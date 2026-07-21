require "test_helper"

class AdminBroadcastsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin duyuru olusturabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-1", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "AdminBroadcast.count", 1 do
      post admin_broadcasts_path, params: { message: "Sistem bakımı 22:00'de." }
    end

    broadcast = AdminBroadcast.last
    assert_equal admin, broadcast.admin
    assert_equal "Sistem bakımı 22:00'de.", broadcast.message
    assert_redirected_to telemetry_path
  end

  test "admin olmayan kullanici duyuru olusturamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "ab-member", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "AdminBroadcast.count" do
      post admin_broadcasts_path, params: { message: "izinsiz" }
    end
    assert_redirected_to root_path
  end

  test "moderator duyuru olusturamaz" do
    mod = User.create!(name: "Mod", provider: "github", uid: "ab-mod", role: "moderator", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_no_difference "AdminBroadcast.count" do
      post admin_broadcasts_path, params: { message: "izinsiz" }
    end
    assert_redirected_to root_path
  end

  test "bos mesaj reddedilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-2", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "AdminBroadcast.count" do
      post admin_broadcasts_path, params: { message: "" }
    end
    assert_redirected_to telemetry_path
  end

  test "yayinlanan duyuru tum giris yapmis kullanicilara layout'ta gorunur" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-3", role: "admin", terms_accepted_at: Time.current)
    AdminBroadcast.create!(admin: admin, message: "HERKESE_GORUNUR_DUYURU_123")

    member = User.create!(name: "Uye", provider: "github", uid: "ab-viewer", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get root_path
    assert_response :success
    assert_match "HERKESE_GORUNUR_DUYURU_123", response.body
  end

  test "suresi dolmus duyuru kullaniciya layout'ta gorunmez" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-4", role: "admin", terms_accepted_at: Time.current)
    AdminBroadcast.create!(admin: admin, message: "SURESI_GECMIS_DUYURU_456", expires_at: 1.hour.ago)

    member = User.create!(name: "Uye2", provider: "github", uid: "ab-viewer-2", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get root_path
    assert_response :success
    assert_no_match "SURESI_GECMIS_DUYURU_456", response.body
  end

  test "giris yapmis herhangi bir kullanici duyuruyu kendi gorunumunden kapatabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-5", role: "admin", terms_accepted_at: Time.current)
    broadcast = AdminBroadcast.create!(admin: admin, message: "kapatilabilir duyuru")

    member = User.create!(name: "Uye3", provider: "github", uid: "ab-viewer-3", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_difference "AdminBroadcastDismissal.count", 1 do
      post dismiss_admin_broadcast_path(broadcast)
    end
    assert AdminBroadcast.exists?(broadcast.id) # duyuru DB'de kaliyor, sadece kapatiliyor
  end

  test "kapatilan duyuru o kullaniciya layout'ta bir daha gorunmez ama DB'de kalir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-6", role: "admin", terms_accepted_at: Time.current)
    broadcast = AdminBroadcast.create!(admin: admin, message: "KAPATILINCA_GIZLENMELI_789")

    member = User.create!(name: "Uye4", provider: "github", uid: "ab-viewer-4", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    post dismiss_admin_broadcast_path(broadcast)

    get root_path
    assert_response :success
    assert_no_match "KAPATILINCA_GIZLENMELI_789", response.body
    assert AdminBroadcast.exists?(broadcast.id)
  end

  test "admin duyuruyu tamamen silebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-7", role: "admin", terms_accepted_at: Time.current)
    broadcast = AdminBroadcast.create!(admin: admin, message: "silinecek duyuru")

    sign_in_via_github(admin)

    assert_difference "AdminBroadcast.count", -1 do
      delete admin_broadcast_path(broadcast)
    end
    assert_redirected_to telemetry_path
  end

  test "admin olmayan kullanici duyuru silemez" do
    admin = User.create!(name: "Root", provider: "github", uid: "ab-admin-8", role: "admin", terms_accepted_at: Time.current)
    broadcast = AdminBroadcast.create!(admin: admin, message: "silinemez duyuru")

    member = User.create!(name: "Uye5", provider: "github", uid: "ab-viewer-5", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "AdminBroadcast.count" do
      delete admin_broadcast_path(broadcast)
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
