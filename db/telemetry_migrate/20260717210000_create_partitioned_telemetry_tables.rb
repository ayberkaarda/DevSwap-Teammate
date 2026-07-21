# Postgres native RANGE partitioning notlari:
# - Partition edilen tablonun PRIMARY KEY'i partition kolonunu (created_at / captured_at)
#   ICERMEK ZORUNDA. Bu yuzden PK composite: activity_logs => (id, created_at),
#   telemetry_snapshots => (id, captured_at). Tek basina `id` uzerinde DB-seviyesinde bir
#   UNIQUE constraint YOK; ancak `id` `bigserial`'dan geldigi icin pratikte hep benzersizdir.
# - activity_logs.user_id artik `users` tablosuna (primary DB'de) gercek bir foreign_key ILE
#   bagli DEGIL. Postgres cross-database foreign key desteklemez. Referans butunlugu yalnizca
#   uygulama seviyesinde saglanir (`ActivityLog belongs_to :user` validasyonu, DB constraint degil).
class CreatePartitionedTelemetryTables < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE activity_logs (
        id bigserial NOT NULL,
        user_id bigint NOT NULL,
        action_type varchar NOT NULL,
        detail text,
        metadata jsonb NOT NULL DEFAULT '{}',
        created_at timestamp(6) NOT NULL,
        updated_at timestamp(6) NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);
    SQL
    execute "CREATE INDEX index_activity_logs_on_user_id_and_created_at ON activity_logs (user_id, created_at);"

    execute <<~SQL
      CREATE TABLE telemetry_snapshots (
        id bigserial NOT NULL,
        active_queue_jobs integer NOT NULL DEFAULT 0,
        captured_at timestamp(6) NOT NULL,
        embeddings_generated_last_hour integer NOT NULL DEFAULT 0,
        failed_queue_jobs integer NOT NULL DEFAULT 0,
        github_scans_last_hour integer NOT NULL DEFAULT 0,
        messages_per_minute integer NOT NULL DEFAULT 0,
        online_users_count integer NOT NULL DEFAULT 0,
        top_skills jsonb NOT NULL DEFAULT '[]',
        created_at timestamp(6) NOT NULL,
        updated_at timestamp(6) NOT NULL,
        PRIMARY KEY (id, captured_at)
      ) PARTITION BY RANGE (captured_at);
    SQL
    execute "CREATE INDEX index_telemetry_snapshots_on_captured_at_brin ON telemetry_snapshots USING brin (captured_at);"

    create_monthly_partitions("activity_logs", "created_at")
    create_monthly_partitions("telemetry_snapshots", "captured_at")
  end

  def down
    drop_table :activity_logs
    drop_table :telemetry_snapshots
  end

  private

  def create_monthly_partitions(table_name, _column, months_ahead: 3)
    start_month = Date.current.beginning_of_month
    (0..months_ahead).each do |offset|
      month_start = start_month + offset.months
      month_end = month_start + 1.month
      partition_name = "#{table_name}_#{month_start.strftime('%Y_%m')}"
      execute <<~SQL
        CREATE TABLE IF NOT EXISTS #{partition_name}
        PARTITION OF #{table_name}
        FOR VALUES FROM ('#{month_start}') TO ('#{month_end}');
      SQL
    end
  end
end
