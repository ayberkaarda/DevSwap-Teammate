class CreateSkillAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_aliases do |t|
      t.string :alias_name, null: false
      t.references :skill, null: false, foreign_key: true
      t.timestamps
    end

    add_index :skill_aliases, :alias_name, unique: true
  end
end
