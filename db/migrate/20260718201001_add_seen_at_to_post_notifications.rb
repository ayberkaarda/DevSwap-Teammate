class AddSeenAtToPostNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :post_notifications, :seen_at, :datetime
  end
end
