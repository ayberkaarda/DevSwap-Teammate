require "test_helper"

class TelemetryControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan kullanici icin aktivite log bolumu gorunmez" do
    viewer = User.create!(name: "Sade Kullanici", provider: "github", uid: "tel-1", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get telemetry_path

    assert_redirected_to root_path
  end

  test "admin kullanici icin kullanici secici gorunur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-2", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match "KULLANICI_AKTİVİTE_LOGU", response.body
  end

  test "admin kullanici user_id ile secilen kullanicinin loglarini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-3", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-4", role: "member", terms_accepted_at: Time.current)
    ActivityLog.record!(target, "login", "#{target.name} giriş yaptı.")

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id)

    assert_response :success
    assert_match "#{target.name} giriş yaptı.", response.body
  end

  test "admin kullanici secilen kullanicinin mesaj ve yetenek gecmisini timeline'da gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-7", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-8", role: "member", terms_accepted_at: Time.current)
    room = chat_rooms(:genel)
    skill = Skill.create!(name: "Haskell", category: "language")

    Message.create!(user: target, chat_room: room, body: "timeline test mesaji")
    UserSkill.create!(user: target, skill: skill, direction: "teaching", source: "manual", weight: nil)

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id)

    assert_response :success
    assert_match "timeline test mesaji", response.body
    assert_match "Haskell", response.body
  end

  test "admin kullanici log_type=login filtresiyle sadece login tipi loglari gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-9", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-10", role: "member", terms_accepted_at: Time.current)
    room = chat_rooms(:genel)

    ActivityLog.record!(target, "login", "#{target.name} giriş yaptı.")
    Message.create!(user: target, chat_room: room, body: "filtrelenmesi gereken mesaj")

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id, log_type: "login")

    assert_response :success
    assert_match "#{target.name} giriş yaptı.", response.body
    assert_no_match "filtrelenmesi gereken mesaj", response.body
  end

  test "admin olmayan kullanici user_id parametresi ile baskasinin logunu goremez" do
    viewer = User.create!(name: "Sade Kullanici", provider: "github", uid: "tel-5", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Gizli Kullanici", provider: "github", uid: "tel-6", role: "member", terms_accepted_at: Time.current)
    ActivityLog.record!(target, "login", "Gizli Kullanıcı özel bir eylem yaptı.")

    sign_in_via_github(viewer)

    get telemetry_path(user_id: target.id)

    assert_redirected_to root_path
  end

  test "giris yapmamis kullanici telemetry sayfasindan reddedilir" do
    get telemetry_path

    assert_redirected_to root_path
  end

  test "moderator telemetry sayfasini hic goremez" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "tel-mod", role: "moderator", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    get telemetry_path

    assert_redirected_to root_path
  end

  test "normal kullanici telemetriyi goremez, root'a yonlendirilir" do
    member = User.create!(name: "Sade", provider: "github", uid: "tel-mem", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get telemetry_path

    assert_redirected_to root_path
  end

  test "admin telemetry sayfasini gorebilir (moderator engeli regresyonu)" do
    admin = User.create!(name: "Root", provider: "github", uid: "tel-adm", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match "KULLANICI_AKTİVİTE_LOGU", response.body
  end

  test "admin kullanici log_type=dm_sent filtresiyle sadece DM mesajlarini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-11", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-12", role: "member", terms_accepted_at: Time.current)
    partner = User.create!(name: "Partner Kullanici", provider: "github", uid: "tel-13", role: "member", terms_accepted_at: Time.current)
    room = chat_rooms(:genel)
    dm_room = ChatRoom.find_or_create_dm_between(target, partner)

    Message.create!(user: target, chat_room: room, body: "genel odaya mesaj")
    Message.create!(user: target, chat_room: dm_room, body: "gizli dm mesaji")

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id, log_type: "dm_sent")

    assert_response :success
    assert_match "gizli dm mesaji", response.body
    assert_no_match "genel odaya mesaj", response.body
    assert_match "DM → #{partner.name}", response.body
  end

  test "admin dm_with_user_id ile iki kullanici arasindaki DM gecmisini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-14", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-15", role: "member", terms_accepted_at: Time.current)
    partner = User.create!(name: "Partner Kullanici", provider: "github", uid: "tel-16", role: "member", terms_accepted_at: Time.current)
    dm_room = ChatRoom.find_or_create_dm_between(target, partner)

    Message.create!(user: target, chat_room: dm_room, body: "merhaba partner")
    Message.create!(user: partner, chat_room: dm_room, body: "merhaba hedef")

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id, dm_with_user_id: partner.id)

    assert_response :success
    assert_match "DM: #{target.name} ↔ #{partner.name}", response.body
    assert_match "merhaba partner", response.body
    assert_match "merhaba hedef", response.body
  end

  test "DM gecmisi bolumu sadece mesaj icerigini gosterir, rating notlarini sizdirmaz (gizlilik regresyonu)" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-17", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-18", role: "member", terms_accepted_at: Time.current)
    partner = User.create!(name: "Partner Kullanici", provider: "github", uid: "tel-19", role: "member", terms_accepted_at: Time.current)
    dm_room = ChatRoom.find_or_create_dm_between(target, partner)

    Message.create!(user: target, chat_room: dm_room, body: "sadece bu mesaj gorunmeli")
    Rating.create!(rater: target, rated_user: partner, chat_room: dm_room, score: 4, note: "cok gizli rating notu")

    sign_in_via_github(admin)

    # log_type=dm_sent ile genel log tablosundaki rating_given satirini disarida birak,
    # boylece sadece DM gecmisi bolumunun (@dm_thread) icerigini izole test edebiliriz.
    get telemetry_path(user_id: target.id, log_type: "dm_sent", dm_with_user_id: partner.id)

    assert_response :success
    assert_match "sadece bu mesaj gorunmeli", response.body
    assert_no_match "cok gizli rating notu", response.body
  end

  test "Faz 20 gizlilik kurali korunuyor: bireysel rating notu normal kullanicilara hic gorunmez" do
    a = User.create!(name: "A Kullanici", provider: "github", uid: "tel-20", role: "member", terms_accepted_at: Time.current)
    b = User.create!(name: "B Kullanici", provider: "github", uid: "tel-21", role: "member", terms_accepted_at: Time.current)
    dm_room = ChatRoom.find_or_create_dm_between(a, b)
    secret_note = "COKGIZLIDEGERLENDIRMENOTU-FAZ29"
    Rating.create!(rater: a, rated_user: b, chat_room: dm_room, score: 1, note: secret_note)

    sign_in_via_github(a)
    get telemetry_path
    assert_redirected_to root_path

    OmniAuth.config.mock_auth[:github] = nil
    sign_in_via_github(b)
    get telemetry_path
    assert_redirected_to root_path
  end

  test "telemetry sayfasi htop sistem monitoru bolumunu gosterir" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-htop", role: "admin", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match "SYSTEM_MONITOR", response.body
    assert_match "EŞLEŞTİRME KUYRUĞU", response.body
  end

  test "normal kullanici da htop sistem monitorunu gorur" do
    member = User.create!(name: "Sade", provider: "github", uid: "tel-htop-mem", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get telemetry_path

    assert_redirected_to root_path
  end

  test "admin rol atama tablosunda kullanicilarin e-posta ve github kullanici adini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-contact-1", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Iletisim Kullanici", provider: "github", uid: "tel-contact-2", email: "hedef@example.com", github_username: "hedefgh", terms_accepted_at: Time.current)

    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match "hedef@example.com", response.body
    assert_match "@hedefgh", response.body
  end

  test "admin susturulmamis bir kullaniciyi telemetriden susturabilir" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-mute-1", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Susturulacak Kullanici", provider: "github", uid: "tel-mute-2", terms_accepted_at: Time.current)

    sign_in_via_github(admin)

    assert_difference "Mute.count", 1 do
      post mutes_path, params: { user_id: target.id, reason: "test", duration_minutes: 60 }
    end
  end

  test "zaten susturulmus kullanici icin telemetride Sustur butonu yerine durum etiketi gorunur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-mute-3", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Zaten Susturulmus", provider: "github", uid: "tel-mute-4", terms_accepted_at: Time.current)
    Mute.create!(user: target, muted_by: admin, muted_until: 1.hour.from_now, active: true)

    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match "zaten susturulmuş", response.body
  end

  test "admin duyuru yayini listesinde her duyuru icin sil butonu gorunur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-del-1", role: "admin", terms_accepted_at: Time.current)
    broadcast = AdminBroadcast.create!(admin: admin, message: "silinebilir telemetri duyurusu")

    sign_in_via_github(admin)

    get telemetry_path

    assert_response :success
    assert_match admin_broadcast_path(broadcast), response.body
  end

  test "aktivite log bolumu turbo_frame ile sarilmis, frame kapsamli GET normal calisir" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-frame-1", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Kullanici", provider: "github", uid: "tel-frame-2", role: "member", terms_accepted_at: Time.current)
    ActivityLog.record!(target, "login", "#{target.name} giriş yaptı.")

    sign_in_via_github(admin)

    get telemetry_path(user_id: target.id), headers: { "Turbo-Frame" => "activity_log_frame" }

    assert_response :success
    assert_match "activity_log_frame", response.body
    assert_match "#{target.name} giriş yaptı.", response.body
  end

  test "admin kuyruk isi drill-down icin ready durumundaki isleri gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-q1", role: "admin", terms_accepted_at: Time.current)
    SolidQueue::Job.create!(queue_name: "default", class_name: "TelemetryTickJob", active_job_id: SecureRandom.uuid, scheduled_at: Time.current)

    sign_in_via_github(admin)

    get telemetry_queue_jobs_path(status: "ready")

    assert_response :success
    assert_match "TelemetryTickJob", response.body
  end

  test "admin kuyruk isi drill-down icin failed durumunda hata mesajini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-q2", role: "admin", terms_accepted_at: Time.current)
    job = SolidQueue::Job.create!(queue_name: "default", class_name: "GithubScanJob", active_job_id: SecureRandom.uuid, scheduled_at: Time.current)
    job.ready_execution&.destroy
    SolidQueue::FailedExecution.create!(job: job, error: { exception_class: "RuntimeError", message: "boom patladi", backtrace: [] })

    sign_in_via_github(admin)

    get telemetry_queue_jobs_path(status: "failed")

    assert_response :success
    assert_match "GithubScanJob", response.body
    assert_match "boom patladi", response.body
  end

  test "kuyruk isi drill-down bos durumda dostane mesaj gosterir" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-q3", role: "admin", terms_accepted_at: Time.current)

    sign_in_via_github(admin)

    get telemetry_queue_jobs_path(status: "claimed")

    assert_response :success
    assert_match "iş bulunmuyor", response.body
  end

  test "admin olmayan kullanici kuyruk isi drill-down endpointine erisemez" do
    viewer = User.create!(name: "Sade Kullanici", provider: "github", uid: "tel-q4", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get telemetry_queue_jobs_path(status: "ready")

    assert_redirected_to root_path
  end

  test "anonim kullanici kuyruk isi drill-down endpointine erisemez" do
    get telemetry_queue_jobs_path(status: "ready")

    assert_redirected_to root_path
  end

  test "admin cevrimici kullanicilar drill-down listesini gorur" do
    admin = User.create!(name: "Root Kullanici", provider: "github", uid: "tel-o1", role: "admin", terms_accepted_at: Time.current)
    online = User.create!(name: "Cevrimici Kullanici", provider: "github", uid: "tel-o2", role: "member", terms_accepted_at: Time.current, is_online: true)
    offline = User.create!(name: "Cevrimdisi Kullanici", provider: "github", uid: "tel-o3", role: "member", terms_accepted_at: Time.current, is_online: false)

    sign_in_via_github(admin)

    get telemetry_online_users_path

    assert_response :success
    assert_match online.name, response.body
    assert_no_match offline.name, response.body
    assert_match public_profile_path(online.id), response.body
  end

  test "admin olmayan kullanici cevrimici kullanicilar endpointine erisemez" do
    viewer = User.create!(name: "Sade Kullanici", provider: "github", uid: "tel-o4", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get telemetry_online_users_path

    assert_redirected_to root_path
  end

  test "anonim kullanici cevrimici kullanicilar endpointine erisemez" do
    get telemetry_online_users_path

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
