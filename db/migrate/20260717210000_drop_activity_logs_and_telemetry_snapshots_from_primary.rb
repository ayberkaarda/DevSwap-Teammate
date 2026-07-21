class DropActivityLogsAndTelemetrySnapshotsFromPrimary < ActiveRecord::Migration[8.1]
  def up
    drop_table :activity_logs
    drop_table :telemetry_snapshots
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Bu tablolar telemetry: veritabanina tasindi (bkz. db/telemetry_migrate), primary'de geri kurulmuyor."
  end
end
