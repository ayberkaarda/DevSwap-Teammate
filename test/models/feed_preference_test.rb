require "test_helper"

class FeedPreferenceTest < ActiveSupport::TestCase
  test "gecerli tercih olusturulabilir" do
    pref = FeedPreference.new(user: users(:one), target_user: users(:two), preference: "interested")
    assert pref.valid?
  end

  test "gecersiz preference reddedilir" do
    pref = FeedPreference.new(user: users(:one), target_user: users(:two), preference: "belki")
    assert_not pref.valid?
  end

  test "kendine tercih belirlenemez" do
    pref = FeedPreference.new(user: users(:one), target_user: users(:one), preference: "interested")
    assert_not pref.valid?
  end

  test "ayni yazar icin ikinci tercih gecersizdir (unique)" do
    FeedPreference.create!(user: users(:one), target_user: users(:two), preference: "interested")
    dup = FeedPreference.new(user: users(:one), target_user: users(:two), preference: "not_interested")
    assert_not dup.valid?
  end

  test "not_interested / interested scope'lari" do
    FeedPreference.create!(user: users(:one), target_user: users(:two), preference: "not_interested")
    assert_equal 1, users(:one).feed_preferences.not_interested.count
    assert_equal 0, users(:one).feed_preferences.interested.count
  end
end
