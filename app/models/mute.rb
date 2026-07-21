class Mute < ApplicationRecord
  belongs_to :user
  belongs_to :muted_by, class_name: "User"

  validates :muted_until, presence: true

  scope :active, -> { where(active: true).where("muted_until > ?", Time.current) }

  def self.active_for?(user)
    return false unless user

    active.exists?(user_id: user.id)
  end
end
