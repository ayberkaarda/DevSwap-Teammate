class CreateDismissedConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :dismissed_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_room, null: false, foreign_key: true
      t.datetime :dismissed_at, null: false

      t.timestamps
    end

    # Bir kullanici + oda cifti icin en fazla tek "gizlendi" kaydi tutulur; tekrar
    # gizlemede kayit guncellenir (upsert semantigi), yeni satir olusturulmaz.
    add_index :dismissed_conversations, [ :user_id, :chat_room_id ], unique: true
  end
end
