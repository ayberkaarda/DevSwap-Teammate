class CreateCommentReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true
      t.string :emoji, null: false
      t.timestamps
    end

    add_index :comment_reactions, [ :user_id, :comment_id, :emoji ],
              unique: true, name: "index_comment_reactions_uniqueness"
  end
end
