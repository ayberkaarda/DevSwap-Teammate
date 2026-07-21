class CreateAdminBroadcastDismissals < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_broadcast_dismissals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :admin_broadcast, null: false, foreign_key: true

      t.timestamps
    end

    # Bir kullanici + duyuru cifti icin en fazla tek "kapatildi" kaydi tutulur
    # (DismissedConversation ile ayni idempotent per-user-per-record deseni).
    add_index :admin_broadcast_dismissals, [ :user_id, :admin_broadcast_id ],
              unique: true, name: "index_broadcast_dismissals_on_user_and_broadcast"
  end
end
