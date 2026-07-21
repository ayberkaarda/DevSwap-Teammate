class AddEditedAtToMessages < ActiveRecord::Migration[8.1]
  def change
    # Mesaj duzenlendiginde doldurulur; nil ise mesaj hic duzenlenmemistir.
    add_column :messages, :edited_at, :datetime
  end
end
