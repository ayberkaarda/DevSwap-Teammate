class AddOriginToChatRooms < ActiveRecord::Migration[8.1]
  def change
    # DM (private) odalarin nasil olusturuldugunu ayirt eder:
    #   "match"  — Dashboard eslesme kartindaki "Baglanti Kur" akisindan.
    #   "direct" — profil "Sohbet Ac" butonundan (varsayilan) veya genel odalar.
    # Genel (public) odalar bu alani onemsemez.
    add_column :chat_rooms, :origin, :string, null: false, default: "direct"
  end
end
