class CreateTelemetrySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :telemetry_snapshots do |t|
      t.datetime :captured_at, null: false
      t.integer :online_users_count, null: false, default: 0
      t.integer :messages_per_minute, default: 0
      t.integer :active_queue_jobs, default: 0
      t.integer :failed_queue_jobs, default: 0
      t.integer :github_scans_last_hour, default: 0
      t.integer :embeddings_generated_last_hour, default: 0
      t.jsonb :top_skills, default: []

      t.timestamps
    end

    add_index :telemetry_snapshots, :captured_at, using: :brin
  end
end
