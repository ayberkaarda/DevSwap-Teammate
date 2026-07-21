class AddExpiresAtToAdminBroadcasts < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_broadcasts, :expires_at, :datetime
  end
end
