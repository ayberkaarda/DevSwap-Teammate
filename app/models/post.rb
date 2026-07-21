class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :post_notifications, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :reposts, dependent: :destroy
  has_many :saved_posts, dependent: :destroy
  has_many :post_shares, dependent: :destroy
  has_many :complaints, dependent: :nullify
  has_and_belongs_to_many :skills

  validates :content, presence: true, length: { maximum: 2000 }
  validates :title, length: { maximum: 120 }, allow_blank: true

  scope :tagged_with, ->(skill) { joins(:skills).where(skills: { id: skill.id }) }

  after_create_commit :trigger_match_calculation

  private

  def trigger_match_calculation
    MatchCalculationJob.perform_later(self)
  end
end
