require "test_helper"

class TelemetryRecordTest < ActiveSupport::TestCase
  test "ActivityLog telemetry veritabanina baglanir" do
    assert_match(/telemetry/, ActivityLog.connection_db_config.database)
  end

  test "TelemetrySnapshot telemetry veritabanina baglanir" do
    assert_match(/telemetry/, TelemetrySnapshot.connection_db_config.database)
  end

  test "TelemetryRecord abstract base primary'den ayri bir baglanti kullanir" do
    refute_equal ActiveRecord::Base.connection_db_config.database,
                 ActivityLog.connection_db_config.database
  end
end
