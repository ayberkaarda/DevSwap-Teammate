require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris gerektirir" do
    get settings_path
    assert_redirected_to root_path
  end

  test "uc bolumu de gosterir: kaydedilenler, ilgilenmediklerim, engellenenler" do
    viewer = User.create!(name: "SettingsUser", provider: "github", uid: "st-1", terms_accepted_at: Time.current)
    author = User.create!(name: "SavedAuthor", provider: "github", uid: "st-2", terms_accepted_at: Time.current)
    disliked = User.create!(name: "DislikedGuy", provider: "github", uid: "st-3", terms_accepted_at: Time.current)
    blocked = User.create!(name: "BlockedGuy", provider: "github", uid: "st-4", terms_accepted_at: Time.current)

    saved_post = Post.create!(content: "SAVED-POST-CONTENT", user: author)
    SavedPost.create!(user: viewer, post: saved_post)
    viewer.feed_preferences.create!(target_user: disliked, preference: "not_interested")
    viewer.blocks_made.create!(blocked: blocked)

    sign_in_via_github(viewer)
    get settings_path

    assert_response :success
    assert_match "SAVED-POST-CONTENT", response.body
    assert_match "DislikedGuy", response.body
    assert_match "BlockedGuy", response.body
    assert_match "Engeli Kaldır", response.body
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end
end
