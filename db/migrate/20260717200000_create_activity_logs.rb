class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action_type, null: false
      t.text :detail
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end
    add_index :activity_logs, [ :user_id, :created_at ]
  end
end
