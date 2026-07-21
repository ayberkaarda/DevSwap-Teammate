require "test_helper"

class RatingTest < ActiveSupport::TestCase
  def build_room(user_a, user_b)
    ChatRoom.find_or_create_dm_between(user_a, user_b)
  end

  test "score 1..5 araligi disinda gecersizdir" do
    rater = User.create!(name: "Rater", provider: "github", uid: "rt-1", terms_accepted_at: Time.current)
    rated = User.create!(name: "Rated", provider: "github", uid: "rt-2", terms_accepted_at: Time.current)
    room = build_room(rater, rated)

    rating = Rating.new(rater: rater, rated_user: rated, chat_room: room, score: 6)
    assert_not rating.valid?
    assert_includes rating.errors[:score], "is not included in the list"

    rating.score = 0
    assert_not rating.valid?

    rating.score = 3
    assert rating.valid?
  end

  test "score olmadan gecersizdir" do
    rater = User.create!(name: "Rater N", provider: "github", uid: "rt-n1", terms_accepted_at: Time.current)
    rated = User.create!(name: "Rated N", provider: "github", uid: "rt-n2", terms_accepted_at: Time.current)
    room = build_room(rater, rated)

    rating = Rating.new(rater: rater, rated_user: rated, chat_room: room)
    assert_not rating.valid?
    assert_includes rating.errors[:score], "can't be blank"
  end

  test "ayni rater ayni odada iki kez degerlendiremez (uniqueness scope chat_room)" do
    rater = User.create!(name: "Rater U", provider: "github", uid: "rt-u1", terms_accepted_at: Time.current)
    rated = User.create!(name: "Rated U", provider: "github", uid: "rt-u2", terms_accepted_at: Time.current)
    room = build_room(rater, rated)

    Rating.create!(rater: rater, rated_user: rated, chat_room: room, score: 4)
    dup = Rating.new(rater: rater, rated_user: rated, chat_room: room, score: 2)

    assert_not dup.valid?
    assert_includes dup.errors[:rater_id], "has already been taken"
  end

  test "after_create_commit rated_user ortalamasini ve sayisini gunceller" do
    rated = User.create!(name: "Rated Avg", provider: "github", uid: "rt-avg", terms_accepted_at: Time.current)
    rater1 = User.create!(name: "Rater A1", provider: "github", uid: "rt-a1", terms_accepted_at: Time.current)
    rater2 = User.create!(name: "Rater A2", provider: "github", uid: "rt-a2", terms_accepted_at: Time.current)

    room1 = build_room(rater1, rated)
    room2 = build_room(rater2, rated)

    Rating.create!(rater: rater1, rated_user: rated, chat_room: room1, score: 4)
    rated.reload
    assert_in_delta 4.0, rated.average_rating, 0.001
    assert_equal 1, rated.ratings_count

    Rating.create!(rater: rater2, rated_user: rated, chat_room: room2, score: 2)
    rated.reload
    assert_in_delta 3.0, rated.average_rating, 0.001
    assert_equal 2, rated.ratings_count
  end
end
