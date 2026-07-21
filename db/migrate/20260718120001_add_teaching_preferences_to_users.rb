class AddTeachingPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :teaching_format, :string
    add_column :users, :availability_note, :string
  end
end
