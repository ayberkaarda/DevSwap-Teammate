class AddGithubFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :avatar_url, :string
    add_column :users, :github_token, :string


    add_index :users, [ :provider, :uid ], unique: true

    add_index :users, [:provider, :uid], unique: true


    add_index :users, [ :provider, :uid ], unique: true

  end
end
