class AddSkillDistributionToUserSkillVectors < ActiveRecord::Migration[8.1]
  def change
    add_column :user_skill_vectors, :skill_distribution, :jsonb, default: {}, null: false
  end
end
