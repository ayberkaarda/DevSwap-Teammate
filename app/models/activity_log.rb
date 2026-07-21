class ActivityLog < TelemetryRecord
  belongs_to :user

  scope :recent, -> { order(created_at: :desc) }

  def self.record!(user, action_type, detail, metadata: {})
    return unless user

    create!(user: user, action_type: action_type, detail: detail, metadata: metadata)
  end
end
