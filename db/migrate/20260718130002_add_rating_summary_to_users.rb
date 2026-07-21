class AddRatingSummaryToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :average_rating, :float
    add_column :users, :ratings_count, :integer, null: false, default: 0
  end
end
