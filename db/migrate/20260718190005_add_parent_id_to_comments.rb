class AddParentIdToComments < ActiveRecord::Migration[8.1]
  def change
    # Self-referential threaded replies. Nullable (top-level comments have no parent).
    add_column :comments, :parent_id, :bigint
    add_index :comments, :parent_id
  end
end
