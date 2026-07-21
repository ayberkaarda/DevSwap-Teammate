class AddDmFieldsToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :private, :boolean, null: false, default: false
    add_reference :chat_rooms, :user_a, null: true, foreign_key: { to_table: :users }
    add_reference :chat_rooms, :user_b, null: true, foreign_key: { to_table: :users }
    add_index :chat_rooms, [ :user_a_id, :user_b_id ], unique: true
  end
end
