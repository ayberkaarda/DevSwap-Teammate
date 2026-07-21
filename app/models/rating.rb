class Rating < ApplicationRecord
  belongs_to :rater, class_name: "User"
  belongs_to :rated_user, class_name: "User"
  belongs_to :chat_room

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :rater_id, uniqueness: { scope: :chat_room_id }

  after_create_commit :recalculate_rated_user_average

  private

  def recalculate_rated_user_average
    stats = Rating.where(rated_user_id: rated_user_id).pick(Arel.sql("AVG(score), COUNT(*)"))
    avg, count = stats
    rated_user.update_columns(average_rating: avg, ratings_count: count)
  end
end
