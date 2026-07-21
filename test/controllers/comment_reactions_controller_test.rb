require "test_helper"

class CommentReactionsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end

  def setup_data
    @user = User.create!(name: "CRC-U", provider: "github", uid: "crc-u", terms_accepted_at: Time.current)
    @post = Post.create!(content: "x", user: @user)
    @comment = Comment.create!(content: "yorum", user: @user, post: @post)
  end

  test "gecerli emoji toggle on/off" do
    setup_data
    sign_in_via_github(@user)
    emoji = CommentReaction::ALLOWED_EMOJI.first

    assert_difference "CommentReaction.count", 1 do
      post toggle_comment_reaction_path(@comment), params: { emoji: emoji }
    end
    assert_difference "CommentReaction.count", -1 do
      post toggle_comment_reaction_path(@comment), params: { emoji: emoji }
    end
  end

  test "gecersiz emoji reddedilir" do
    setup_data
    sign_in_via_github(@user)

    assert_no_difference "CommentReaction.count" do
      post toggle_comment_reaction_path(@comment), params: { emoji: "xxx" }
    end
  end

  test "giris gerektirir" do
    setup_data
    assert_no_difference "CommentReaction.count" do
      post toggle_comment_reaction_path(@comment), params: { emoji: CommentReaction::ALLOWED_EMOJI.first }
    end
    assert_redirected_to root_path
  end
end
