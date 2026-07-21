require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "girişte activity log olusturulur" do
    user = User.create!(name: "Giris Kullanicisi", provider: "github", uid: "sess-1", terms_accepted_at: Time.current)

    assert_difference "ActivityLog.count", 1 do
      sign_in_via_github(user)
    end

    log = ActivityLog.last
    assert_equal user, log.user
    assert_equal "login", log.action_type
  end

  test "cikista activity log olusturulur" do
    user = User.create!(name: "Cikis Kullanicisi", provider: "github", uid: "sess-2", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    assert_difference "ActivityLog.count", 1 do
      delete logout_path
    end

    log = ActivityLog.last
    assert_equal user, log.user
    assert_equal "logout", log.action_type
  end

  test "banli hesap login sirasinda reddedilir" do
    user = User.create!(name: "Banli Kullanici", provider: "github", uid: "sess-banned", terms_accepted_at: Time.current)
    admin = User.create!(name: "Root", provider: "github", uid: "sess-admin", role: "admin", terms_accepted_at: Time.current)
    BannedAccount.create!(provider: "github", uid: "sess-banned", active: true, banned_by: admin)

    sign_in_via_github(user)

    assert_redirected_to root_path
    assert_match "yasaklandı", flash[:alert]
    assert_nil session[:user_id]
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
