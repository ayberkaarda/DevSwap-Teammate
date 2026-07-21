class GithubRepository < ApplicationRecord
  belongs_to :user

  scope :visible, -> { where(visible_on_profile: true) }
end
