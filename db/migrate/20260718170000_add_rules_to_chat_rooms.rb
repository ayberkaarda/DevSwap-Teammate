class AddRulesToChatRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_rooms, :rules, :text
  end
end
