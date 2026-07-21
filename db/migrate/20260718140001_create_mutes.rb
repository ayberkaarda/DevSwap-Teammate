class CreateMutes < ActiveRecord::Migration[8.1]
  def change
    create_table :mutes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :muted_by, null: false, foreign_key: { to_table: :users }
      t.text :reason
      t.datetime :muted_until, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
