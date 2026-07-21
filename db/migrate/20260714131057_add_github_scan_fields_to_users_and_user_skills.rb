class AddGithubScanFieldsToUsersAndUserSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :github_username, :string
    add_column :users, :github_repos_etag, :string
    add_column :users, :skills_last_scanned_at, :datetime

    add_column :user_skills, :weight, :float
    add_column :user_skills, :source, :string, default: "manual", null: false



    add_index :user_skills, [ :user_id, :skill_id, :source ], unique: true, name: "index_user_skills_on_user_skill_source"

    add_index :user_skills, [:user_id, :skill_id, :source], unique: true, name: "index_user_skills_on_user_skill_source"

    add_index :user_skills, [ :user_id, :skill_id, :source ], unique: true, name: "index_user_skills_on_user_skill_source"

  end
end
