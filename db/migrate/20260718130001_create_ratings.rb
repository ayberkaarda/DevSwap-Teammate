class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :rater, null: false, foreign_key: { to_table: :users }
      t.references :rated_user, null: false, foreign_key: { to_table: :users }
      t.references :chat_room, null: false, foreign_key: true
      t.integer :score, null: false
      t.text :note
      t.timestamps
    end
    add_index :ratings, [ :chat_room_id, :rater_id ], unique: true
  end
end
