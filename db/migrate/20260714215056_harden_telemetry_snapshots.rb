class HardenTelemetrySnapshots < ActiveRecord::Migration[8.1]
  def up
    change_column_null :telemetry_snapshots, :online_users_count, false
    change_column_null :telemetry_snapshots, :messages_per_minute, false
    change_column_null :telemetry_snapshots, :active_queue_jobs, false
    change_column_null :telemetry_snapshots, :failed_queue_jobs, false
    change_column_null :telemetry_snapshots, :github_scans_last_hour, false
    change_column_null :telemetry_snapshots, :embeddings_generated_last_hour, false
    change_column_null :telemetry_snapshots, :top_skills, false

    remove_index :telemetry_snapshots, :captured_at, name: "index_telemetry_snapshots_on_captured_at"
    add_index :telemetry_snapshots, :captured_at, using: :brin, name: "index_telemetry_snapshots_on_captured_at_brin"
  end

  def down
    remove_index :telemetry_snapshots, :captured_at, name: "index_telemetry_snapshots_on_captured_at_brin"
    add_index :telemetry_snapshots, :captured_at, name: "index_telemetry_snapshots_on_captured_at"

    change_column_null :telemetry_snapshots, :online_users_count, true
    change_column_null :telemetry_snapshots, :messages_per_minute, true
    change_column_null :telemetry_snapshots, :active_queue_jobs, true
    change_column_null :telemetry_snapshots, :failed_queue_jobs, true
    change_column_null :telemetry_snapshots, :github_scans_last_hour, true
    change_column_null :telemetry_snapshots, :embeddings_generated_last_hour, true
    change_column_null :telemetry_snapshots, :top_skills, true
  end
end
