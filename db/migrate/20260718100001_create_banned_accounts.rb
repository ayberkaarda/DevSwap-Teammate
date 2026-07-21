class CreateBannedAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :banned_accounts do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.text :reason
      t.datetime :banned_until
      t.boolean :active, null: false, default: true
      t.references :banned_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :banned_accounts, [ :provider, :uid ], unique: true
  end
end
