require "test_helper"

class PostShareTest < ActiveSupport::TestCase
  def setup
    @sender = User.create!(name: "PS-S", provider: "github", uid: "ps-s", terms_accepted_at: Time.current)
    @recipient = User.create!(name: "PS-R", provider: "github", uid: "ps-r", terms_accepted_at: Time.current)
    @post = Post.create!(content: "icerik", user: @sender)
  end

  test "gonderen, post ve alici iliskileri calisir" do
    share = PostShare.create!(user: @sender, post: @post, recipient: @recipient)
    assert_equal @sender, share.user
    assert_equal @recipient, share.recipient
    assert_equal @post, share.post
  end

  test "ayni post ayni kisiye birden fazla kez gonderilebilir (unique DEGIL)" do
    assert_difference "PostShare.count", 2 do
      PostShare.create!(user: @sender, post: @post, recipient: @recipient)
      PostShare.create!(user: @sender, post: @post, recipient: @recipient)
    end
  end
end
