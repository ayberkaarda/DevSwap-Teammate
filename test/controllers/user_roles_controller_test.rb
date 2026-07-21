require "test_helper"

class UserRolesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan kullanici rol degistiremez" do
    member = User.create!(name: "Uye", provider: "github", uid: "ur-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ur-target-1", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    patch user_role_path(target), params: { role: "moderator" }

    assert_redirected_to root_path
    assert_equal "member", target.reload.role
  end

  test "admin bir kullaniciyi moderator yapabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ur-admin-1", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ur-target-2", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    patch user_role_path(target), params: { role: "moderator" }

    assert_equal "moderator", target.reload.role
    assert_redirected_to telemetry_path
  end

  test "gecersiz rol string'i reddedilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ur-admin-2", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ur-target-3", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    patch user_role_path(target), params: { role: "superadmin" }

    assert_equal "member", target.reload.role
    assert_redirected_to telemetry_path
    assert_equal "Geçersiz rol.", flash[:alert]
  end

  test "korumali admin hesabinin rolu baska bir admin tarafindan dusurulemez" do
    admin = User.create!(name: "Root", provider: "github", uid: "ur-admin-prot", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu", provider: "github", uid: "ur-protected", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    patch user_role_path(protected_user), params: { role: "member" }

    assert_equal "admin", protected_user.reload.role
    assert_redirected_to telemetry_path
    assert_equal "Bu hesabın admin yetkisi kaldırılamaz.", flash[:alert]
  end

  test "moderator rol degisikligi yapamaz" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "ur-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ur-target-4", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    patch user_role_path(target), params: { role: "admin" }

    assert_redirected_to root_path
    assert_equal "member", target.reload.role
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
