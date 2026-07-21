class MatchDigest < ApplicationRecord
  belongs_to :user

  scope :unseen, -> { where(seen_at: nil) }
  scope :active, -> { where(created_at: 14.days.ago..) }

  # matched_user_ids Postgres jsonb'den dogrudan Ruby Array olarak gelir
  # (serialize gerekmez), bu yuzden id listesiyle User sorgusu yeterli.
  def matched_users
    User.where(id: matched_user_ids)
  end

  def seen?
    seen_at.present?
  end
end
