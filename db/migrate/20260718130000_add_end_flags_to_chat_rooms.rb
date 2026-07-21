class AddEndFlagsToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :ended_by_a, :boolean, null: false, default: false
    add_column :chat_rooms, :ended_by_b, :boolean, null: false, default: false
  end
end
