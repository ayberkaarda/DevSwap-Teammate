class TelemetryTickJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: "telemetry_tick", duration: 10.seconds

  LAST_PERSISTED_CACHE_KEY = "telemetry:last_persisted_at"
  PERSIST_INTERVAL = 1.minute

  # htop-tarzı canlı sistem monitörü için anlık veri. SolidQueue execution
  # tablolarındaki iş dağılımı, yaklaşık çevrimiçi kullanıcı sayısı ve eşleştirme
  # (MatchCalculationJob) kuyruğunun derinliği. View (_widgets) bu şekli bekler:
  # { solid_queue_jobs_by_status: { ready:, scheduled:, claimed:, failed: },
  #   online_users:, match_queue_depth: }
  def self.htop_data
    {
      solid_queue_jobs_by_status: {
        ready: SolidQueue::ReadyExecution.count,
        scheduled: SolidQueue::ScheduledExecution.count,
        claimed: SolidQueue::ClaimedExecution.count,
        failed: SolidQueue::FailedExecution.count
      },
      online_users: User.where(is_online: true).count,
      match_queue_depth: SolidQueue::Job.where(class_name: "MatchCalculationJob", finished_at: nil).count
    }
  end


  def perform
    begin
      attrs = {
        captured_at: Time.current,
        online_users_count: User.where(is_online: true).count,
        messages_per_minute: Message.where(created_at: 1.minute.ago..).count,
        active_queue_jobs: SolidQueue::Job.where(finished_at: nil).count,
        failed_queue_jobs: SolidQueue::FailedExecution.count,
        github_scans_last_hour: User.where(skills_last_scanned_at: 1.hour.ago..).count,
        embeddings_generated_last_hour: UserSkillVector.where(generated_at: 1.hour.ago..).count,
        top_skills: Skill.joins(:user_skills)
                          .group(:name)
                          .order(Arel.sql("count(user_skills.id) desc"))
                          .limit(5)
                          .count("user_skills.id")
                          .map { |name, count| { name: name, count: count } }
      }

      if should_persist?
        TelemetrySnapshot.create!(attrs)
        Rails.cache.write(LAST_PERSISTED_CACHE_KEY, Time.current)
        # Retention is handled exclusively by TelemetryPartitionMaintenanceJob, which
        # DROPs whole monthly partitions instead of DELETEing rows. Row-level pruning
        # is intentionally absent here — telemetry_snapshots is a 12-month historical
        # table, not a rolling window.
      end

      current_snapshot = TelemetrySnapshot.new(attrs)

      Turbo::StreamsChannel.broadcast_replace_to(
        "telemetry_dashboard",
        target: "telemetry-widgets",
        partial: "telemetry/widgets",
        locals: { snapshot: current_snapshot, history: TelemetrySnapshot.history, htop: self.class.htop_data }
      )
    rescue => e
      Rails.logger.error("[TelemetryTickJob] #{e.class}: #{e.message}")
    ensure
      self.class.set(wait: 1.second).perform_later unless Rails.env.test?
    end
  end



  private

  def should_persist?
    last_persisted_at = Rails.cache.read(LAST_PERSISTED_CACHE_KEY)
    last_persisted_at.nil? || last_persisted_at <= PERSIST_INTERVAL.ago
  end
end
