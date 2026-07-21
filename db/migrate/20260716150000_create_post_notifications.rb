class CreatePostNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :post_notifications do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :skill, foreign_key: true
      t.datetime :dismissed_at
      t.datetime :claimed_at
      t.timestamps
      t.index [ :post_id, :user_id ], unique: true
    end
  end
end
