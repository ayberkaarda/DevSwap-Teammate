class PostNotification < ApplicationRecord
  belongs_to :post
  belongs_to :user
  belongs_to :skill, optional: true

  scope :active, -> { where(dismissed_at: nil) }

  # Kullanicinin henuz gormedigi (zil menusu acilmamis / gecmis sayfasi
  # ziyaret edilmemis) bildirimler. Zil rozetindeki "+N" sayaci bunlari sayar.
  scope :unseen, -> { where(seen_at: nil) }

  def seen?
    seen_at.present?
  end
end
