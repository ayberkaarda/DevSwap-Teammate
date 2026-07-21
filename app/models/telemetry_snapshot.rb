
class TelemetrySnapshot < TelemetryRecord
  scope :recent, -> { order(captured_at: :desc) }

  def self.latest = recent.first
  def self.history(limit = 60) = recent.limit(limit).to_a.reverse
end
