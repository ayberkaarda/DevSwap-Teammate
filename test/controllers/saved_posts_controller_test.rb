require "test_helper"

class SavedPostsControllerTest < ActionDispatch::IntegrationTest
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

  def user!(uid)
    User.create!(name: "S-#{uid}", provider: "github", uid: uid, terms_accepted_at: Time.current)
  end

  test "kaydetme toggle on/off" do
    u = user!("sc-1")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    assert_difference "SavedPost.count", 1 do
      post toggle_save_post_path(p)
    end
    assert_difference "SavedPost.count", -1 do
      post toggle_save_post_path(p)
    end
  end

  test "giris gerektirir" do
    u = user!("sc-anon")
    p = Post.create!(content: "x", user: u)
    assert_no_difference "SavedPost.count" do
      post toggle_save_post_path(p)
    end
    assert_redirected_to root_path
  end
end
