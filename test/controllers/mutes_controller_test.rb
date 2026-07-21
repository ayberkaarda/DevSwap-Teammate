require "test_helper"

class MutesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "staff olmayan kullanici mute olusturamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "mc-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "mc-t1", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "Mute.count" do
      post mutes_path, params: { user_id: target.id, reason: "test", duration_minutes: 30 }
    end
    assert_redirected_to root_path
  end

  test "moderator bir kullaniciyi susturabilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "mc-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "mc-t2", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_difference "Mute.count", 1 do
      post mutes_path, params: { user_id: target.id, reason: "spam", duration_minutes: 30 }
    end
    mute = Mute.last
    assert_equal target, mute.user
    assert_equal mod, mute.muted_by
    assert mute.muted_until > Time.current

    log = ActivityLog.where(action_type: "user_muted").order(:created_at).last
    assert_equal mod, log.user
    assert_match target.name, log.detail
    assert_equal target.id, log.metadata["target_id"]
    assert_equal 30, log.metadata["duration_minutes"]
  end

  test "admin bir kullaniciyi susturabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "mc-admin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "mc-t3", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "Mute.count", 1 do
      post mutes_path, params: { user_id: target.id, reason: "spam" }
    end
  end

  test "korumali hesap baska bir admin tarafindan susturulamaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "mc-admin-prot", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu", provider: "github", uid: "mc-protected", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "Mute.count" do
      post mutes_path, params: { user_id: protected_user.id, reason: "olmaz", duration_minutes: 30 }
    end

    assert_match "moderasyondan korunuyor", flash[:alert]
  end

  test "staff susturmayi kaldirabilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "mc-mod2", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "mc-t4", terms_accepted_at: Time.current)
    mute = Mute.create!(user: target, muted_by: mod, muted_until: 1.hour.from_now, active: true)
    sign_in_via_github(mod)

    delete mute_path(mute)

    assert_not mute.reload.active?

    log = ActivityLog.where(action_type: "user_unmuted").order(:created_at).last
    assert_equal mod, log.user
    assert_match target.name, log.detail
    assert_equal target.id, log.metadata["target_id"]
    assert_equal mute.id, log.metadata["mute_id"]
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
