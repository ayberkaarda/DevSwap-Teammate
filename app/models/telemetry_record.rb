class TelemetryRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :telemetry, reading: :telemetry }
end
