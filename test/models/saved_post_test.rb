require "test_helper"

class SavedPostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "SP-U", provider: "github", uid: "sp-u", terms_accepted_at: Time.current)
    @post = Post.create!(content: "icerik", user: @user)
  end

  test "ayni kullanici ayni postu iki kez kaydedemez (uniqueness)" do
    SavedPost.create!(user: @user, post: @post)
    dup = SavedPost.new(user: @user, post: @post)

    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "toggle acar ve kapatir" do
    assert_difference "SavedPost.count", 1 do
      assert_equal true, SavedPost.toggle(user: @user, post: @post)
    end
    assert_difference "SavedPost.count", -1 do
      assert_equal false, SavedPost.toggle(user: @user, post: @post)
    end
  end
end
