class UserActivityTimeline
  PER_SOURCE_LIMIT = 200

  TimelineEvent = Data.define(:created_at, :action_type, :detail)

  def self.call(user, limit: 200)
    new(user, limit).call
  end

  def initialize(user, limit)
    @user = user
    @limit = limit
  end

  def call
    events = activity_log_events + message_events + skill_added_events + rating_given_events +
             warning_events + mute_events + complaint_received_events
    events.sort_by(&:created_at).reverse.first(@limit)
  end

  private

  def activity_log_events
    @user.activity_logs.order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |log|
      TimelineEvent.new(created_at: log.created_at, action_type: log.action_type, detail: log.detail)
    end
  end

  def message_events
    @user.messages.includes(chat_room: [ :user_a, :user_b ]).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |message|
      room = message.chat_room
      room_label = if room&.private?
        other = room.other_participant(@user)
        "DM → #{other&.name || 'bilinmeyen'}"
      else
        room&.name || "bilinmeyen"
      end
      TimelineEvent.new(
        created_at: message.created_at,
        action_type: room&.private? ? "dm_sent" : "message_sent",
        detail: "#{@user.name} \"#{room_label}\" odasına mesaj gönderdi: \"#{message.body.to_s.truncate(80)}\""
      )
    end
  end

  def skill_added_events
    @user.user_skills.includes(:skill).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |user_skill|
      direction_label = user_skill.direction == "teaching" ? "öğretebileceği" : "öğrenmek istediği"
      TimelineEvent.new(
        created_at: user_skill.created_at,
        action_type: "skill_added",
        detail: "#{@user.name} \"#{user_skill.skill&.name}\" yeteneğini #{direction_label} yetenek olarak ekledi."
      )
    end
  end

  def warning_events
    UserWarning.where(user_id: @user.id).includes(:issued_by).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |w|
      TimelineEvent.new(created_at: w.created_at, action_type: "warning_received", detail: "#{w.issued_by.name} tarafından uyarıldı: \"#{w.reason}\"")
    end
  end

  def mute_events
    Mute.where(user_id: @user.id).includes(:muted_by).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |m|
      TimelineEvent.new(created_at: m.created_at, action_type: "mute_applied", detail: "#{m.muted_by.name} tarafından #{m.muted_until.strftime('%d.%m.%Y %H:%M')}'e kadar susturuldu: \"#{m.reason}\"")
    end
  end

  def complaint_received_events
    Complaint.where(target_user_id: @user.id).includes(:reported_by).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |c|
      TimelineEvent.new(created_at: c.created_at, action_type: "complaint_received", detail: "#{c.reported_by.name} tarafından şikayet edildi: \"#{c.description}\"")
    end
  end

  def rating_given_events
    Rating.where(rater_id: @user.id).includes(:rated_user).order(created_at: :desc).limit(PER_SOURCE_LIMIT).map do |rating|
      TimelineEvent.new(
        created_at: rating.created_at,
        action_type: "rating_given",
        detail: "#{@user.name} \"#{rating.rated_user.name}\" kişisine #{rating.score}/5 puan verdi: \"#{rating.note.presence || 'not yok'}\""
      )
    end
  end
end
