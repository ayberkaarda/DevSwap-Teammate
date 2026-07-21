class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :chat_rooms, :slug, unique: true

    add_reference :messages, :chat_room, foreign_key: true

    reversible do |dir|
      dir.up do
        default_room_id = execute(
          "INSERT INTO chat_rooms (name, slug, position, created_at, updated_at) VALUES ('Genel', 'genel', 0, NOW(), NOW()) RETURNING id"
        ).first["id"]
        execute("UPDATE messages SET chat_room_id = #{default_room_id} WHERE chat_room_id IS NULL")
      end
    end

    change_column_null :messages, :chat_room_id, false
  end
end
