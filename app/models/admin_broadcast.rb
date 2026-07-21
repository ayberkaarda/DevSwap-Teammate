class AdminBroadcast < ApplicationRecord
  belongs_to :admin, class_name: "User"
  has_many :admin_broadcast_dismissals, dependent: :destroy

  MAX_MESSAGE_LENGTH = 500

  validates :message, presence: true, length: { maximum: MAX_MESSAGE_LENGTH }

  # Tum giris yapmis kullanicilara gosterilen en son duyurular (en yeni ustte).
  scope :recent, ->(limit = 3) { order(created_at: :desc).limit(limit) }

  # Suresi dolmamis (ya da suresiz) duyurular. Admin bir duyuruya sure verdiginde
  # (expires_at) o an gecince kullanicilardan otomatik kaybolur.
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
