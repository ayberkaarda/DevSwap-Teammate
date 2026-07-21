require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan uye paneli goremez" do
    member = User.create!(name: "Uye", provider: "github", uid: "au-member", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get admin_users_path

    assert_redirected_to root_path
  end

  test "moderator paneli gorebilir (require_staff)" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "au-mod", role: "moderator", terms_accepted_at: Time.current)
    listed = User.create!(name: "Listelenen Kisi Mod", provider: "github", uid: "au-listed-mod", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    get admin_users_path

    assert_response :success
    assert_match "Listelenen Kisi Mod", response.body
  end

  test "moderator bu sayfadan bir kullaniciyi susturabilir" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "au-mod-2", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Susturulacak Kisi", provider: "github", uid: "au-target", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_difference "Mute.count", 1 do
      post mutes_path, params: { user_id: target.id, reason: "admin panelinden susturuldu", duration_minutes: 60 }
    end

    assert Mute.where(user: target, active: true).exists?
  end

  test "admin index'i gorebilir ve kullanicilar listelenir" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-1", role: "admin", terms_accepted_at: Time.current)
    listed = User.create!(name: "Listelenen Kisi", provider: "github", uid: "au-listed", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get admin_users_path

    assert_response :success
    assert_match "Listelenen Kisi", response.body
  end

  test "arama isme gore filtreler" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-2", role: "admin", terms_accepted_at: Time.current)
    match = User.create!(name: "Zebra Kullanici", provider: "github", uid: "au-zebra", email: "zebra@example.com", role: "member", terms_accepted_at: Time.current)
    nomatch = User.create!(name: "Kaplan Kullanici", provider: "github", uid: "au-kaplan", email: "kaplan@example.com", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get admin_users_path, params: { q: "zebra" }

    assert_response :success
    assert_match "Zebra Kullanici", response.body
    assert_no_match "Kaplan Kullanici", response.body
  end

  test "role filtresi sadece admin rolundekileri dondurur" do
    admin = User.create!(name: "Root Admin", provider: "github", uid: "au-admin-3", role: "admin", terms_accepted_at: Time.current)
    member = User.create!(name: "Sade Uye", provider: "github", uid: "au-plain-member", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get admin_users_path, params: { filter: "admin" }

    assert_response :success
    assert_match "Root Admin", response.body
    assert_no_match "Sade Uye", response.body
  end

  test "banned filtresi sadece banli kullaniciyi gosterir" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-4", role: "admin", terms_accepted_at: Time.current)
    banned_user = User.create!(name: "Banli Kisi", provider: "github", uid: "au-banned", role: "member", terms_accepted_at: Time.current)
    clean_user = User.create!(name: "Temiz Kisi", provider: "github", uid: "au-clean", role: "member", terms_accepted_at: Time.current)
    BannedAccount.create!(provider: "github", uid: "au-banned", active: true, banned_by: admin)
    sign_in_via_github(admin)

    get admin_users_path, params: { filter: "banned" }

    assert_response :success
    assert_match "Banli Kisi", response.body
    assert_no_match "Temiz Kisi", response.body
  end

  test "muted filtresi sadece susturulmus kullaniciyi gosterir" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-5", role: "admin", terms_accepted_at: Time.current)
    muted_user = User.create!(name: "Susturulmus Kisi", provider: "github", uid: "au-muted", role: "member", terms_accepted_at: Time.current)
    normal_user = User.create!(name: "Normal Kisi", provider: "github", uid: "au-normal", role: "member", terms_accepted_at: Time.current)
    Mute.create!(user: muted_user, muted_by: admin, active: true, muted_until: 1.hour.from_now)
    sign_in_via_github(admin)

    get admin_users_path, params: { filter: "muted" }

    assert_response :success
    assert_match "Susturulmus Kisi", response.body
    assert_no_match "Normal Kisi", response.body
  end

  test "korumali kullanici icin sustur butonu render edilmez ama badge gorunur" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-6", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu Kisi", provider: "github", uid: "au-protected", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get admin_users_path

    assert_response :success
    # korumali badge gorunur
    assert_match "korumalı", response.body

    # korumali kullanicinin id'sini hedefleyen bir mute formu olmamali
    assert_select "form[action=?]", mutes_path do |forms|
      forms.each do |form|
        assert_select form, "input[name='user_id'][value=?]", protected_user.id.to_s, count: 0
      end
    end
  end

  test "sayfada ban butonu ve rol secimi artik gorunmuyor" do
    admin = User.create!(name: "Root", provider: "github", uid: "au-admin-7", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Sade Kisi", provider: "github", uid: "au-plain", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get admin_users_path

    assert_response :success
    assert_no_match "Banla", response.body
    assert_select "form[action=?]", bans_path, count: 0
    assert_select "select[name=?]", "role", count: 0
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
