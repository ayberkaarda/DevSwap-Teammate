class CreateWarnings < ActiveRecord::Migration[8.1]
  def change
    create_table :warnings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :issued_by, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.timestamps
    end
  end
end
