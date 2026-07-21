class CreateAdminBroadcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_broadcasts do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.text :message, null: false
      t.timestamps
    end
  end
end
