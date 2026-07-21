class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followee, class_name: "User"

  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:followee_id, "kendini takip edemezsin") if follower_id == followee_id
  end
end
