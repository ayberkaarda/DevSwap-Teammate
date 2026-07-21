require "test_helper"

class FollowTest < ActiveSupport::TestCase
  test "gecerli takip olusturulabilir" do
    follow = Follow.new(follower: users(:one), followee: users(:two))
    assert follow.valid?
  end

  test "kendini takip edemez" do
    follow = Follow.new(follower: users(:one), followee: users(:one))
    assert_not follow.valid?
    assert_includes follow.errors[:followee_id], "kendini takip edemezsin"
  end

  test "ayni ikili icin ikinci takip gecersizdir (unique)" do
    Follow.create!(follower: users(:one), followee: users(:two))
    dup = Follow.new(follower: users(:one), followee: users(:two))
    assert_not dup.valid?
  end

  test "following / followers iliskileri ve sayaclar" do
    users(:one).active_follows.create!(followee: users(:two))

    assert users(:one).following?(users(:two))
    assert_includes users(:one).following, users(:two)
    assert_includes users(:two).followers, users(:one)
    assert_equal 1, users(:one).following_count
    assert_equal 1, users(:two).followers_count
    assert_equal 0, users(:one).followers_count
  end
end
