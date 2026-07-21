require "test_helper"

class ChatCommandsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  # --- /mute ---

  test "staff bir kullaniciyi terminal komutuyla susturabilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "cc-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-t1", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_difference "Mute.count", 1 do
      post mute_chat_command_path, params: { username: "Hedef", duration: "30 dakika" }, as: :json
    end

    body = JSON.parse(response.body)
    assert body["ok"]
    mute = Mute.last
    assert_equal target, mute.user
    assert_equal mod, mute.muted_by
    assert mute.muted_until > Time.current
  end

  test "non-staff kullanici terminal komutuyla susturamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "cc-member", role: "member", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-t2", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "Mute.count" do
      post mute_chat_command_path, params: { username: "Hedef", duration: "30 dakika" }, as: :json
    end

    assert_response :forbidden
    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "yetkin yok", body["message"]
  end

  test "korumali hesap terminal komutuyla susturulamaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-admin", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Kurucu", provider: "github", uid: "cc-prot", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "Mute.count" do
      post mute_chat_command_path, params: { username: "Kurucu", duration: "30 dakika" }, as: :json
    end

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "moderasyondan korunuyor", body["message"]
  end

  test "eslesmeyen kullanici adi net hata dondurur ve mute olusturmaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-admin2", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "Mute.count" do
      post mute_chat_command_path, params: { username: "YokBoyleBiri", duration: "30" }, as: :json
    end

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "bulunamadı", body["message"]
  end

  test "birden fazla eslesen kullanici adi net hata dondurur ve mute olusturmaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-admin3", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Ikiz", provider: "github", uid: "cc-dup1", terms_accepted_at: Time.current)
    User.create!(name: "ikiz", provider: "github", uid: "cc-dup2", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "Mute.count" do
      post mute_chat_command_path, params: { username: "Ikiz", duration: "30" }, as: :json
    end

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "birden fazla", body["message"]
  end

  test "sure ayristirma: 30 dakika -> 30" do
    assert_muted_for_minutes("30 dakika", 30, "cc-d1")
  end

  test "sure ayristirma: 1 saat -> 60" do
    assert_muted_for_minutes("1 saat", 60, "cc-d2")
  end

  test "sure ayristirma: ciplak 45 -> 45" do
    assert_muted_for_minutes("45", 45, "cc-d3")
  end

  test "sure bos ise varsayilan 60 dakika" do
    assert_muted_for_minutes("", 60, "cc-d4")
  end

  # --- /unmute ---

  test "staff aktif susturmayi terminal komutuyla kaldirabilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "cc-umod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-ut1", terms_accepted_at: Time.current)
    mute = Mute.create!(user: target, muted_by: mod, muted_until: 1.hour.from_now, active: true)
    sign_in_via_github(mod)

    post unmute_chat_command_path, params: { username: "Hedef" }, as: :json

    body = JSON.parse(response.body)
    assert body["ok"]
    assert_not mute.reload.active?
  end

  test "non-staff terminal komutuyla susturma kaldiramaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "cc-umember", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-ut2", terms_accepted_at: Time.current)
    mod = User.create!(name: "Mod", provider: "github", uid: "cc-umod2", role: "moderator", terms_accepted_at: Time.current)
    mute = Mute.create!(user: target, muted_by: mod, muted_until: 1.hour.from_now, active: true)
    sign_in_via_github(member)

    post unmute_chat_command_path, params: { username: "Hedef" }, as: :json

    assert_response :forbidden
    assert mute.reload.active?
  end

  test "aktif susturmasi olmayan kullanici icin net mesaj dondurur" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-uadmin", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-ut3", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    post unmute_chat_command_path, params: { username: "Hedef" }, as: :json

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "susturulmuş değil", body["message"]
  end

  # --- /block, /unblock (self-service, staff yetkisi GEREKMEZ) ---

  test "non-staff kullanici bile terminal komutuyla baskasini engelleyebilir" do
    member = User.create!(name: "Engelleyen", provider: "github", uid: "cc-bl-m", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Engellenen", provider: "github", uid: "cc-bl-t", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_difference "Block.count", 1 do
      post block_chat_command_path, params: { username: "Engellenen" }, as: :json
    end

    body = JSON.parse(response.body)
    assert body["ok"]
    assert member.reload.blocking?(target)
  end

  test "kendini terminal komutuyla engelleyemez" do
    member = User.create!(name: "KendiEngel", provider: "github", uid: "cc-bl-self", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "Block.count" do
      post block_chat_command_path, params: { username: "KendiEngel" }, as: :json
    end
    body = JSON.parse(response.body)
    assert_not body["ok"]
  end

  test "terminal komutuyla engel kaldirilabilir" do
    member = User.create!(name: "EngelKaldiran", provider: "github", uid: "cc-ubl-m", terms_accepted_at: Time.current)
    target = User.create!(name: "EskiEngelli", provider: "github", uid: "cc-ubl-t", terms_accepted_at: Time.current)
    member.blocks_made.create!(blocked: target)
    sign_in_via_github(member)

    assert_difference "Block.count", -1 do
      post unblock_chat_command_path, params: { username: "EskiEngelli" }, as: :json
    end
    body = JSON.parse(response.body)
    assert body["ok"]
    assert_not member.reload.blocking?(target)
  end

  test "zaten engelli olmayan icin unblock net mesaj dondurur" do
    member = User.create!(name: "Bosuna", provider: "github", uid: "cc-ubl-none", terms_accepted_at: Time.current)
    User.create!(name: "HicEngelsiz", provider: "github", uid: "cc-ubl-t2", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    post unblock_chat_command_path, params: { username: "HicEngelsiz" }, as: :json
    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "zaten engelli değil", body["message"]
  end

  # --- /ban ---

  test "admin bir kullaniciyi terminal komutuyla banlayabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-admin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-ban-t1", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "BannedAccount.count", 1 do
      post ban_chat_command_path, params: { username: "Hedef", duration: "" }, as: :json
    end

    body = JSON.parse(response.body)
    assert body["ok"], "beklenen basari, gelen: #{body.inspect}"
    ban = BannedAccount.last
    assert ban.active?
    assert_equal target.provider, ban.provider
    assert_equal target.uid, ban.uid
    assert_equal admin, ban.banned_by
  end

  test "admin aktif bani terminal komutuyla kaldirabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-uadmin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-ban-ut1", terms_accepted_at: Time.current)
    active_ban = BannedAccount.create!(provider: target.provider, uid: target.uid, active: true, banned_by: admin)
    sign_in_via_github(admin)

    post unban_chat_command_path, params: { username: "Hedef" }, as: :json

    body = JSON.parse(response.body)
    assert body["ok"], "beklenen basari, gelen: #{body.inspect}"
    assert_not active_ban.reload.active?
  end

  test "non-admin staff terminal komutuyla banlayamaz" do
    mod = User.create!(name: "Mod", provider: "github", uid: "cc-ban-mod", role: "moderator", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-ban-t2", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_no_difference "BannedAccount.count" do
      post ban_chat_command_path, params: { username: "Hedef", duration: "7" }, as: :json
    end

    assert_response :forbidden
    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "yetkin yok", body["message"]
  end

  test "non-admin staff terminal komutuyla ban kaldiramaz" do
    mod = User.create!(name: "Mod", provider: "github", uid: "cc-ban-umod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-ban-ut2", terms_accepted_at: Time.current)
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-umod-a", role: "admin", terms_accepted_at: Time.current)
    active_ban = BannedAccount.create!(provider: target.provider, uid: target.uid, active: true, banned_by: admin)
    sign_in_via_github(mod)

    post unban_chat_command_path, params: { username: "Hedef" }, as: :json

    assert_response :forbidden
    assert active_ban.reload.active?
  end

  test "korumali hesap terminal komutuyla banlanamaz" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-padmin", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Kurucu", provider: "github", uid: "cc-ban-prot", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_no_difference "BannedAccount.count" do
      post ban_chat_command_path, params: { username: "Kurucu", duration: "7" }, as: :json
    end

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "moderasyondan korunuyor", body["message"]
  end

  test "aktif bani olmayan kullanici icin unban net mesaj dondurur" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-nadmin", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-ban-none", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    post unban_chat_command_path, params: { username: "Hedef" }, as: :json

    body = JSON.parse(response.body)
    assert_not body["ok"]
    assert_match "zaten banlı değil", body["message"]
  end

  test "ban sure ayristirma: 7 gün -> ~7 gun sonra" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-d1a", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-ban-d1t", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    freeze_time do
      post ban_chat_command_path, params: { username: "Hedef", duration: "7 gün" }, as: :json
      body = JSON.parse(response.body)
      assert body["ok"], "beklenen basari, gelen: #{body.inspect}"
      ban = BannedAccount.last
      assert_not_nil ban.banned_until
      assert_in_delta 7.days.from_now.to_f, ban.banned_until.to_f, 5
    end
  end

  test "ban sure bos ise suresiz (banned_until nil)" do
    admin = User.create!(name: "Root", provider: "github", uid: "cc-ban-d2a", role: "admin", terms_accepted_at: Time.current)
    User.create!(name: "Hedef", provider: "github", uid: "cc-ban-d2t", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    post ban_chat_command_path, params: { username: "Hedef", duration: "" }, as: :json
    body = JSON.parse(response.body)
    assert body["ok"], "beklenen basari, gelen: #{body.inspect}"
    ban = BannedAccount.last
    assert_nil ban.banned_until
    assert_match "süresiz", body["message"]
  end

  private

  def assert_muted_for_minutes(duration_text, expected_minutes, uid_suffix)
    admin = User.create!(name: "Root", provider: "github", uid: "root-#{uid_suffix}", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "tgt-#{uid_suffix}", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    freeze_time do
      post mute_chat_command_path, params: { username: "Hedef", duration: duration_text }, as: :json
      body = JSON.parse(response.body)
      assert body["ok"], "beklenen basari, gelen: #{body.inspect}"
      mute = Mute.last
      actual_minutes = ((mute.muted_until - Time.current) / 60).round
      assert_equal expected_minutes, actual_minutes
    end
  end

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
