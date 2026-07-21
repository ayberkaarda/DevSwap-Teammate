class AddVisibleOnProfileToGithubRepositories < ActiveRecord::Migration[8.1]
  def change
    add_column :github_repositories, :visible_on_profile, :boolean, null: false, default: true
  end
end
