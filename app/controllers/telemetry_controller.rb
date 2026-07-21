class TelemetryController < ApplicationController
  before_action :require_admin

  def show
    @snapshot = TelemetrySnapshot.latest
    @history = TelemetrySnapshot.history
    @htop = TelemetryTickJob.htop_data
    TelemetryTickJob.perform_later if @snapshot.nil? || @snapshot.captured_at < 3.seconds.ago

    @users = User.order(:name)

    # Fix 3: Rol Atama tablosunda "Sustur" butonu icin — Admin::UsersController#index
    # ile ayni desen (susturulmus kullanici id kumesi, tek sorgu, N+1 yok).
    @muted_user_ids = Mute.active.pluck(:user_id).to_set

    # Task 1: admin duyurulari — telemetride yayinlanmis son duyurular.
    @recent_broadcasts = AdminBroadcast.includes(:admin).recent(5)

    @selected_user = User.find_by(id: params[:user_id]) if params[:user_id].present?
    @activity_timeline = UserActivityTimeline.call(@selected_user) if @selected_user

    if @activity_timeline && params[:log_type].present?
      @activity_timeline = @activity_timeline.select { |event| event.action_type == params[:log_type] }
    end

    if @selected_user && params[:dm_with_user_id].present?
      other = User.find_by(id: params[:dm_with_user_id])
      if other
        dm_room = ChatRoom.where(private: true)
                           .where("(user_a_id = :a AND user_b_id = :b) OR (user_a_id = :b AND user_b_id = :a)", a: @selected_user.id, b: other.id)
                           .first
        @dm_thread = dm_room&.messages&.includes(:user)&.order(created_at: :asc)
        @dm_other_user = other
      end
    end
  end

  # Faz: SYSTEM_MONITOR (htop) durum satirlarina tiklama ile drill-down.
  # Sayimla AYNI sorgu semantigini kullanir (bkz. TelemetryTickJob.htop_data):
  # ready/scheduled/claimed = ilgili SolidQueue execution tablosu, failed = FailedExecution.
  QUEUE_STATUS_SCOPES = {
    "ready" => SolidQueue::ReadyExecution,
    "scheduled" => SolidQueue::ScheduledExecution,
    "claimed" => SolidQueue::ClaimedExecution,
    "failed" => SolidQueue::FailedExecution
  }.freeze

  QUEUE_JOBS_LIMIT = 50

  def queue_jobs
    status = params[:status].to_s
    scope_class = QUEUE_STATUS_SCOPES[status]

    jobs =
      if scope_class
        scope_class.includes(:job)
                    .order(id: :desc)
                    .limit(QUEUE_JOBS_LIMIT)
                    .filter_map do |execution|
                      job = execution.job
                      next if job.nil?

                      {
                        class_name: job.class_name,
                        queue_name: job.queue_name,
                        error_message: (status == "failed" ? failed_execution_message(execution) : nil)
                      }
                    end
      else
        []
      end

    render partial: "telemetry/queue_jobs_list", locals: { jobs: jobs, status: status }, layout: false
  end

  # "Cevrimici Kullanici" stat kutusu drill-down. TelemetryTickJob#perform ile
  # AYNI "online" tanimini kullanir: User.where(is_online: true).
  def online_users
    users = User.where(is_online: true).order(:name).limit(QUEUE_JOBS_LIMIT)

    render partial: "telemetry/online_users_list", locals: { users: users }, layout: false
  end

  helper_method :user_muted?

  private

  def failed_execution_message(execution)
    message = execution.message.to_s
    message = "Hata mesajı yok" if message.blank?
    message.truncate(200)
  rescue StandardError
    "Hata mesajı okunamadı"
  end

  def user_muted?(user)
    @muted_user_ids.include?(user.id)
  end
end
