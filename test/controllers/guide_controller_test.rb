require "test_helper"

class GuideControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmis kullanici kilavuz sayfasini gorebilir" do
    user = User.create!(name: "Sade Kullanici", provider: "github", uid: "guide-1", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    get guide_path

    assert_response :success
    assert_match "Yapabileceklerim", response.body
  end

  test "giris yapmamis kullanici kilavuz sayfasindan reddedilir" do
    get guide_path

    assert_redirected_to root_path
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )

    get "/auth/github/callback"
  end
end
