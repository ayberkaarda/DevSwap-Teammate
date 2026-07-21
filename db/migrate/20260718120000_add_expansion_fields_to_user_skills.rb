class AddExpansionFieldsToUserSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :user_skills, :proficiency_level, :string
    add_column :user_skills, :note, :text
    add_column :user_skills, :evidence_url, :string
  end
end
