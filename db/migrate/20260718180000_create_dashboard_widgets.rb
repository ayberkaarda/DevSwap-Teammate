class CreateDashboardWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboard_widgets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :widget_type, null: false
      t.integer :position_x, null: false, default: 0
      t.integer :position_y, null: false, default: 0
      t.integer :width, null: false, default: 4
      t.integer :height, null: false, default: 3
      t.decimal :font_scale, null: false, default: 1.0, precision: 4, scale: 2
      t.boolean :visible, null: false, default: true

      t.timestamps
    end

    add_index :dashboard_widgets, [ :user_id, :widget_type ], unique: true
  end
end
