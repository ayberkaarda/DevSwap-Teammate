class TelemetryPartitionMaintenanceJob < ApplicationJob
  queue_as :default

  RETENTION_MONTHS = 12
  MONTHS_AHEAD = 3
  TABLES = { "activity_logs" => ActivityLog, "telemetry_snapshots" => TelemetrySnapshot }.freeze

  def perform
    TABLES.each do |table_name, model|
      ensure_future_partitions(table_name, model)
      drop_old_partitions(table_name, model)
    end
  end

  private

  def ensure_future_partitions(table_name, model)
    start_month = Date.current.beginning_of_month
    (0..MONTHS_AHEAD).each do |offset|
      month_start = start_month + offset.months
      month_end = month_start + 1.month
      partition_name = "#{table_name}_#{month_start.strftime('%Y_%m')}"
      model.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{partition_name}
        PARTITION OF #{table_name}
        FOR VALUES FROM ('#{month_start}') TO ('#{month_end}');
      SQL
    end
  end

  def drop_old_partitions(table_name, model)
    cutoff_month = (Date.current.beginning_of_month - RETENTION_MONTHS.months)
    result = model.connection.execute(<<~SQL)
      SELECT inhrelid::regclass::text AS partition_name
      FROM pg_inherits
      WHERE inhparent = '#{table_name}'::regclass
    SQL

    result.each do |row|
      partition_name = row["partition_name"]
      match = partition_name.match(/_(\d{4})_(\d{2})\z/)
      next unless match

      partition_month = Date.new(match[1].to_i, match[2].to_i, 1)
      next unless partition_month < cutoff_month

      model.connection.execute("DROP TABLE IF EXISTS #{partition_name}")
      Rails.logger.info("[TelemetryPartitionMaintenanceJob] Dropped old partition: #{partition_name}")
    end
  end
end
