require "test_helper"

class RepostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "RP-U", provider: "github", uid: "rp-u", terms_accepted_at: Time.current)
    @post = Post.create!(content: "icerik", user: @user)
  end

  test "ayni kullanici ayni postu iki kez repost edemez (uniqueness)" do
    Repost.create!(user: @user, post: @post)
    dup = Repost.new(user: @user, post: @post)

    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "toggle acar ve kapatir" do
    assert_difference "Repost.count", 1 do
      assert_equal true, Repost.toggle(user: @user, post: @post)
    end
    assert_difference "Repost.count", -1 do
      assert_equal false, Repost.toggle(user: @user, post: @post)
    end
  end

  test "post.reposts iliskisi calisir" do
    Repost.create!(user: @user, post: @post)
    assert_equal 1, @post.reposts.size
  end
end
