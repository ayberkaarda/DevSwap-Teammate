class CreatePostsSkillsJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_join_table :posts, :skills do |t|
      t.index [ :post_id, :skill_id ], unique: true
    end
  end
end
