# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_17_210000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_logs", primary_key: ["id", "created_at"], options: "PARTITION BY RANGE (created_at)", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.bigserial "id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_activity_logs_on_user_id_and_created_at"
  end

  create_table "activity_logs_2026_07", primary_key: ["id", "created_at"], options: "INHERITS (activity_logs)", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.bigint "id", default: -> { "nextval('activity_logs_id_seq'::regclass)" }, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "activity_logs_2026_07_user_id_created_at_idx"
  end

  create_table "activity_logs_2026_08", primary_key: ["id", "created_at"], options: "INHERITS (activity_logs)", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.bigint "id", default: -> { "nextval('activity_logs_id_seq'::regclass)" }, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "activity_logs_2026_08_user_id_created_at_idx"
  end

  create_table "activity_logs_2026_09", primary_key: ["id", "created_at"], options: "INHERITS (activity_logs)", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.bigint "id", default: -> { "nextval('activity_logs_id_seq'::regclass)" }, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "activity_logs_2026_09_user_id_created_at_idx"
  end

  create_table "activity_logs_2026_10", primary_key: ["id", "created_at"], options: "INHERITS (activity_logs)", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.bigint "id", default: -> { "nextval('activity_logs_id_seq'::regclass)" }, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at"], name: "activity_logs_2026_10_user_id_created_at_idx"
  end

  create_table "telemetry_snapshots", primary_key: ["id", "captured_at"], options: "PARTITION BY RANGE (captured_at)", force: :cascade do |t|
    t.integer "active_queue_jobs", default: 0, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "embeddings_generated_last_hour", default: 0, null: false
    t.integer "failed_queue_jobs", default: 0, null: false
    t.integer "github_scans_last_hour", default: 0, null: false
    t.bigserial "id", null: false
    t.integer "messages_per_minute", default: 0, null: false
    t.integer "online_users_count", default: 0, null: false
    t.jsonb "top_skills", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "index_telemetry_snapshots_on_captured_at_brin", using: :brin
  end

  create_table "telemetry_snapshots_2026_07", primary_key: ["id", "captured_at"], options: "INHERITS (telemetry_snapshots)", force: :cascade do |t|
    t.integer "active_queue_jobs", default: 0, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "embeddings_generated_last_hour", default: 0, null: false
    t.integer "failed_queue_jobs", default: 0, null: false
    t.integer "github_scans_last_hour", default: 0, null: false
    t.bigint "id", default: -> { "nextval('telemetry_snapshots_id_seq'::regclass)" }, null: false
    t.integer "messages_per_minute", default: 0, null: false
    t.integer "online_users_count", default: 0, null: false
    t.jsonb "top_skills", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "telemetry_snapshots_2026_07_captured_at_idx", using: :brin
  end

  create_table "telemetry_snapshots_2026_08", primary_key: ["id", "captured_at"], options: "INHERITS (telemetry_snapshots)", force: :cascade do |t|
    t.integer "active_queue_jobs", default: 0, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "embeddings_generated_last_hour", default: 0, null: false
    t.integer "failed_queue_jobs", default: 0, null: false
    t.integer "github_scans_last_hour", default: 0, null: false
    t.bigint "id", default: -> { "nextval('telemetry_snapshots_id_seq'::regclass)" }, null: false
    t.integer "messages_per_minute", default: 0, null: false
    t.integer "online_users_count", default: 0, null: false
    t.jsonb "top_skills", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "telemetry_snapshots_2026_08_captured_at_idx", using: :brin
  end

  create_table "telemetry_snapshots_2026_09", primary_key: ["id", "captured_at"], options: "INHERITS (telemetry_snapshots)", force: :cascade do |t|
    t.integer "active_queue_jobs", default: 0, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "embeddings_generated_last_hour", default: 0, null: false
    t.integer "failed_queue_jobs", default: 0, null: false
    t.integer "github_scans_last_hour", default: 0, null: false
    t.bigint "id", default: -> { "nextval('telemetry_snapshots_id_seq'::regclass)" }, null: false
    t.integer "messages_per_minute", default: 0, null: false
    t.integer "online_users_count", default: 0, null: false
    t.jsonb "top_skills", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "telemetry_snapshots_2026_09_captured_at_idx", using: :brin
  end

  create_table "telemetry_snapshots_2026_10", primary_key: ["id", "captured_at"], options: "INHERITS (telemetry_snapshots)", force: :cascade do |t|
    t.integer "active_queue_jobs", default: 0, null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.integer "embeddings_generated_last_hour", default: 0, null: false
    t.integer "failed_queue_jobs", default: 0, null: false
    t.integer "github_scans_last_hour", default: 0, null: false
    t.bigint "id", default: -> { "nextval('telemetry_snapshots_id_seq'::regclass)" }, null: false
    t.integer "messages_per_minute", default: 0, null: false
    t.integer "online_users_count", default: 0, null: false
    t.jsonb "top_skills", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["captured_at"], name: "telemetry_snapshots_2026_10_captured_at_idx", using: :brin
  end
end
