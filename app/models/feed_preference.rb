class FeedPreference < ApplicationRecord
  INTERESTED = "interested".freeze
  NOT_INTERESTED = "not_interested".freeze
  PREFERENCES = [ INTERESTED, NOT_INTERESTED ].freeze

  belongs_to :user
  belongs_to :target_user, class_name: "User"

  validates :preference, inclusion: { in: PREFERENCES }
  validates :user_id, uniqueness: { scope: :target_user_id }
  validate :cannot_target_self

  scope :interested, -> { where(preference: INTERESTED) }
  scope :not_interested, -> { where(preference: NOT_INTERESTED) }

  private

  def cannot_target_self
    errors.add(:target_user_id, "kendine tercih belirleyemezsin") if user_id == target_user_id
  end
end
