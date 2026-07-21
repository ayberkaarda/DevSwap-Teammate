class SavedPost < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user_id, uniqueness: { scope: :post_id }

  # Toggle semantigi ("post kaydetme").
  def self.toggle(user:, post:)
    existing = find_by(user: user, post: post)
    if existing
      existing.destroy
      false
    else
      create!(user: user, post: post)
      true
    end
  end
end
