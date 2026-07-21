class MessageReaction < ApplicationRecord
  # Chat mesajlarina birakilan emoji tepkileri (POST yorumlarindaki CommentReaction'dan
  # AYRIDIR). Ayni kucuk, sabit izin listesi kullanilir — keyfi stringler reddedilir.
  # (CommentReaction ayri bir baglama ait oldugundan liste bilincli olarak burada
  # tekrarlanir; iki model birbirine sızmasız kalır.)
  ALLOWED_EMOJI = %w[👍 ❤️ 😂 😮 😢 🎉 🔥 🚀].freeze

  belongs_to :user
  belongs_to :message

  validates :emoji, presence: true, inclusion: { in: ALLOWED_EMOJI }
  # Ayni kullanici ayni mesaja AYNI emoji'yi bir kez birakabilir, ama FARKLI
  # emoji'lerle birden fazla tepki verebilir (unique scope emoji'yi de icerir).
  validates :user_id, uniqueness: { scope: [ :message_id, :emoji ] }

  # Toggle: ayni emoji tekrar birakilinca kaldirilir.
  def self.toggle(user:, message:, emoji:)
    existing = find_by(user: user, message: message, emoji: emoji)
    if existing
      existing.destroy
      false
    else
      create!(user: user, message: message, emoji: emoji)
      true
    end
  end

  # Bir mesajin emoji -> sayi dagilimi (yayin payload'u icin).
  def self.counts_for(message)
    where(message: message).group(:emoji).count
  end
end
