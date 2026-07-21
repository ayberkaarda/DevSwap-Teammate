class CreateComplaints < ActiveRecord::Migration[8.1]
  def change
    create_table :complaints do |t|
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.text :description, null: false
      t.timestamps
    end
  end
end
