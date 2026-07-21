require "test_helper"

class TelemetryPartitionMaintenanceJobTest < ActiveSupport::TestCase
  def partition_names(table_name)
    conn = ActivityLog.connection
    result = conn.execute(<<~SQL)
      SELECT inhrelid::regclass::text AS partition_name
      FROM pg_inherits
      WHERE inhparent = '#{table_name}'::regclass
    SQL
    result.map { |row| row["partition_name"] }
  end

  test "gelecekteki aylik partition'lar olusturulur" do
    TelemetryPartitionMaintenanceJob.perform_now

    start_month = Date.current.beginning_of_month
    (0..TelemetryPartitionMaintenanceJob::MONTHS_AHEAD).each do |offset|
      month = start_month + offset.months
      expected = "activity_logs_#{month.strftime('%Y_%m')}"
      assert_includes partition_names("activity_logs"), expected,
                      "#{expected} partition'i olusturulmali"

      expected_snap = "telemetry_snapshots_#{month.strftime('%Y_%m')}"
      assert_includes partition_names("telemetry_snapshots"), expected_snap,
                      "#{expected_snap} partition'i olusturulmali"
    end
  end

  test "retention penceresinden eski partition'lar dusurulur" do
    old_month = Date.current.beginning_of_month - (TelemetryPartitionMaintenanceJob::RETENTION_MONTHS + 1).months
    old_partition = "activity_logs_#{old_month.strftime('%Y_%m')}"
    conn = ActivityLog.connection
    conn.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{old_partition}
      PARTITION OF activity_logs
      FOR VALUES FROM ('#{old_month}') TO ('#{old_month + 1.month}');
    SQL

    assert_includes partition_names("activity_logs"), old_partition

    TelemetryPartitionMaintenanceJob.perform_now

    refute_includes partition_names("activity_logs"), old_partition,
                    "#{old_partition} retention disinda oldugu icin dusurulmeli"
  end
end
