require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "toggle bir kez cagirinca takip eder" do
    viewer = User.create!(name: "Follower", provider: "github", uid: "fl-1", terms_accepted_at: Time.current)
    target = User.create!(name: "Followee", provider: "github", uid: "fl-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "Follow.count", 1 do
      post toggle_follow_path, params: { target_user_id: target.id }
    end
    assert viewer.reload.following?(target)
  end

  test "toggle ikinci cagirinca takibi birakir" do
    viewer = User.create!(name: "Follower2", provider: "github", uid: "fl-3", terms_accepted_at: Time.current)
    target = User.create!(name: "Followee2", provider: "github", uid: "fl-4", terms_accepted_at: Time.current)
    viewer.active_follows.create!(followee: target)
    sign_in_via_github(viewer)

    assert_difference "Follow.count", -1 do
      post toggle_follow_path, params: { target_user_id: target.id }
    end
    assert_not viewer.reload.following?(target)
  end

  test "kendini takip edemez" do
    viewer = User.create!(name: "SelfFollow", provider: "github", uid: "fl-5", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_no_difference "Follow.count" do
      post toggle_follow_path, params: { target_user_id: viewer.id }
    end
  end

  test "giris yapmamis kullanici takip edemez" do
    target = User.create!(name: "NoAuthFollowee", provider: "github", uid: "fl-6", terms_accepted_at: Time.current)
    assert_no_difference "Follow.count" do
      post toggle_follow_path, params: { target_user_id: target.id }
    end
    assert_redirected_to root_path
  end

  test "followers/following listeleri herkese acik gorunur" do
    owner = User.create!(name: "ListOwner", provider: "github", uid: "fl-7", terms_accepted_at: Time.current)
    fan = User.create!(name: "FanUser", provider: "github", uid: "fl-8", terms_accepted_at: Time.current)
    fan.active_follows.create!(followee: owner)

    get public_profile_followers_path(owner.id)
    assert_response :success
    assert_match "FanUser", response.body

    get public_profile_following_path(fan.id)
    assert_response :success
    assert_match "ListOwner", response.body
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
