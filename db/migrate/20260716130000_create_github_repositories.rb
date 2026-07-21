class CreateGithubRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :github_repositories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :full_name, null: false
      t.text :description
      t.string :primary_language
      t.integer :stargazers_count, default: 0
      t.string :html_url, null: false
      t.datetime :repo_updated_at
      t.timestamps
      t.index [ :user_id, :full_name ], unique: true
    end
  end
end
