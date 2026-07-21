class CommentReaction < ApplicationRecord
  # Kucuk, sabit bir emoji izin listesi — keyfi stringler reddedilir.
  ALLOWED_EMOJI = %w[👍 ❤️ 😂 😮 😢 🎉 🔥 🚀].freeze

  belongs_to :user
  belongs_to :comment

  validates :emoji, presence: true, inclusion: { in: ALLOWED_EMOJI }
  # Ayni kullanici ayni yoruma AYNI emoji'yi bir kez birakabilir, ama FARKLI
  # emoji'lerle birden fazla tepki verebilir (unique scope emoji'yi de icerir).
  validates :user_id, uniqueness: { scope: [ :comment_id, :emoji ] }

  # Toggle: ayni emoji tekrar birakilinca kaldirilir.
  def self.toggle(user:, comment:, emoji:)
    existing = find_by(user: user, comment: comment, emoji: emoji)
    if existing
      existing.destroy
      false
    else
      create!(user: user, comment: comment, emoji: emoji)
      true
    end
  end
end
