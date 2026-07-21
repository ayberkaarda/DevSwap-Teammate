class CreateMessageReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :message_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :message, null: false, foreign_key: true
      t.string :emoji, null: false
      t.timestamps
    end

    add_index :message_reactions, [ :user_id, :message_id, :emoji ],
              unique: true, name: "index_message_reactions_uniqueness"
  end
end
