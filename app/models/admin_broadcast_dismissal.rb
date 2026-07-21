class AdminBroadcastDismissal < ApplicationRecord
  belongs_to :user
  belongs_to :admin_broadcast

  validates :user_id, uniqueness: { scope: :admin_broadcast_id }

  # Bir kullanicinin bir duyuruyu "kapatmasi" (kalici, cihazlar arasi):
  # var olan kaydi gunceller, yoksa olusturur. Silme DEGIL — sadece o kullanici
  # icin banner'dan gizleme (DismissedConversation.dismiss! ile ayni desen).
  def self.dismiss!(user, admin_broadcast)
    record = find_or_initialize_by(user_id: user.id, admin_broadcast_id: admin_broadcast.id)
    record.save! if record.new_record?
    record
  end

  # Su an kullanici tarafindan kapatilmis duyuru id'leri.
  def self.dismissed_broadcast_ids_for(user)
    where(user_id: user.id).pluck(:admin_broadcast_id)
  end
end
