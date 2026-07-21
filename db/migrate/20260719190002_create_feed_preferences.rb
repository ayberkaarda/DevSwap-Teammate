class CreateFeedPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.string :preference, null: false
      t.timestamps
    end

    add_index :feed_preferences, [ :user_id, :target_user_id ], unique: true
  end
end
