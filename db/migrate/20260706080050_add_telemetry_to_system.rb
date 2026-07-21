class AddTelemetryToSystem < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_online, :boolean, default: false
    add_column :messages, :is_read, :boolean, default: false
  end
end
