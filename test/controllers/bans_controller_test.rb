require "test_helper"

class BansControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan kullanici ban olusturamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "bc-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-1", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "BannedAccount.count" do
      post bans_path, params: { user_id: target.id, reason: "test" }
    end

    assert_redirected_to root_path
  end

  test "admin bir kullaniciyi suresiz banlayabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-1", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-2", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "BannedAccount.count", 1 do
      post bans_path, params: { user_id: target.id, reason: "kural ihlali" }
    end

    ban = BannedAccount.last
    assert_equal "github", ban.provider
    assert_equal target.uid, ban.uid
    assert ban.permanent?
    assert_equal admin, ban.banned_by
    assert_redirected_to telemetry_path
  end

  test "admin bir kullaniciyi sureli banlayabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-2", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-3", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    post bans_path, params: { user_id: target.id, reason: "gecici", duration_days: 7 }

    ban = BannedAccount.last
    assert_not ban.permanent?
    assert ban.banned_until > 6.days.from_now
  end

  test "github hesabi olmayan kullanici banlanamaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-3", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hesapsiz", provider: nil, uid: nil, email: "hesapsiz@example.com", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "BannedAccount.count" do
      post bans_path, params: { user_id: target.id, reason: "olmaz" }
    end
  end

  test "banli kullanici login sirasinda reddedilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-4", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-4", terms_accepted_at: Time.current)
    sign_in_via_github(admin)
    post bans_path, params: { user_id: target.id, reason: "test" }

    sign_in_via_github(target)

    assert_redirected_to root_path
    assert_match "Bu GitHub hesabı yasaklandı.", flash[:alert]
  end

  test "oturumu acikken banlanan kullanici bir sonraki isteginde reddedilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-6", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-6", terms_accepted_at: Time.current)

    target_session = open_session
    target_session.instance_eval do
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
        provider: "github", uid: target.uid,
        info: { name: target.name, email: target.email, nickname: target.uid, image: nil },
        credentials: { token: "test-token" }
      )
      get "/auth/github/callback"
      get root_path
    end
    assert_equal 200, target_session.response.status, target_session.response.body

    sign_in_via_github(admin)
    post bans_path, params: { user_id: target.id, reason: "sonradan banlandi" }

    target_session.instance_eval { get root_path }
    assert_equal 302, target_session.response.status
    assert_match root_path, target_session.response.redirect_url
  end

  test "admin bani kaldirabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-5", role: "admin", terms_accepted_at: Time.current)
    ban = BannedAccount.create!(provider: "github", uid: "bc-target-5", active: true, banned_by: admin)
    sign_in_via_github(admin)

    delete ban_path(ban)

    assert_not ban.reload.active?
    assert_redirected_to telemetry_path
  end

  test "korumali hesap baska bir admin tarafindan banlanamaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "bc-admin-prot", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu", provider: "github", uid: "bc-protected", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "BannedAccount.count" do
      post bans_path, params: { user_id: protected_user.id, reason: "olmaz" }
    end

    assert_redirected_to telemetry_path
    assert_match "moderasyondan korunuyor", flash[:alert]
  end

  test "moderator ban action'ina erisemez (require_admin'e takilir)" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "bc-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "bc-target-mod", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_no_difference "BannedAccount.count" do
      post bans_path, params: { user_id: target.id, reason: "moderator banlayamaz" }
    end

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
