class RenameContinuousTypeToDirectionOnUserSkills < ActiveRecord::Migration[8.1]
  def change
    rename_column :user_skills, :continuous_type, :direction
  end
end
