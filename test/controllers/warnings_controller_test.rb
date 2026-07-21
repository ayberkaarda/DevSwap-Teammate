require "test_helper"

class WarningsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "staff olmayan kullanici uyari gonderemez" do
    member = User.create!(name: "Uye", provider: "github", uid: "wc-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wc-t1", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "UserWarning.count" do
      post warnings_path, params: { user_id: target.id, reason: "test" }
    end
    assert_redirected_to root_path
  end

  test "moderator uyari gonderebilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "wc-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wc-t2", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_difference "UserWarning.count", 1 do
      post warnings_path, params: { user_id: target.id, reason: "kural ihlali" }
    end
    assert_equal mod, UserWarning.last.issued_by
  end

  test "admin uyari gonderebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "wc-admin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wc-t3", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "UserWarning.count", 1 do
      post warnings_path, params: { user_id: target.id, reason: "kural ihlali" }
    end
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
