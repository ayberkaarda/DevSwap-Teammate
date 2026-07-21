require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmamis ziyaretci baskasinin profilini gorebilir" do
    owner = User.create!(name: "Profil Sahibi", provider: "github", uid: "pc-1", terms_accepted_at: Time.current)

    get public_profile_path(owner)

    assert_response :success
    assert_match owner.name, response.body
  end

  test "var olmayan id icin root_path'e yonlendirir" do
    get public_profile_path(id: 999_999)

    assert_redirected_to root_path
  end

  test "kullanici kendi profiline bakinca match analizi gosterilmez" do
    user = User.create!(name: "Kendi Profili", provider: "github", uid: "pc-2", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    get public_profile_path(user)

    assert_response :success
    assert_no_match(/EŞLEŞME_ANALİZİ/, response.body)
  end

  test "eslesmesi olmayan kullanicilar arasinda bile sohbet ac butonu gosterilir" do
    viewer = User.create!(name: "Eslesme Yok Ziyaretci", provider: "github", uid: "pc-10", terms_accepted_at: Time.current)
    owner = User.create!(name: "Eslesme Yok Hedef", provider: "github", uid: "pc-11", terms_accepted_at: Time.current)

    sign_in_via_github(viewer)

    get public_profile_path(owner)

    assert_response :success
    assert_no_match(/EŞLEŞME_ANALİZİ/, response.body)
    assert_match "Sohbet Aç", response.body
  end

  test "kullanici kendi profiline bakinca sohbet ac butonu gosterilmez" do
    user = User.create!(name: "Kendi Profili Buton", provider: "github", uid: "pc-12", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    get public_profile_path(user)

    assert_response :success
    assert_no_match "Sohbet Aç", response.body
  end

  # NOT: "match_analysis" widget'ı profilden kaldırıldığı için eski
  # "match analizi gosterilir" testi silindi. Aşağıdaki testler match analizinin
  # artık HİÇBİR ziyaretçiye gösterilmediğini (ve sayfanın patlamadığını) doğrular.

  test "viewer'in embedding vektoru yokken baskasinin profili 500 vermez" do
    # Regresyon: MatchFinder fallback modunda duz User dondurur (Match sarmalayicisi
    # olmadan). View bu durumda match metodlarini cagirmamali, sayfa 200 donmeli.
    viewer = User.create!(name: "Vektorsuz Ziyaretci", provider: "github", uid: "pc-6", terms_accepted_at: Time.current)
    owner = User.create!(name: "Hedef Profil", provider: "github", uid: "pc-7", terms_accepted_at: Time.current)

    assert_nil UserSkillVector.find_by(user: viewer)

    sign_in_via_github(viewer)

    get public_profile_path(owner)

    assert_response :success
    assert_no_match(/EŞLEŞME_ANALİZİ/, response.body)
  end

  test "profil sahibinin repolari stargazers_count'a gore siralanip listelenir" do
    owner = User.create!(name: "Repo Profil", provider: "github", uid: "pc-5", terms_accepted_at: Time.current)
    GithubRepository.create!(user: owner, name: "az-yildiz", full_name: "owner/az-yildiz",
                             html_url: "https://github.com/owner/az-yildiz", stargazers_count: 3)
    GithubRepository.create!(user: owner, name: "cok-yildiz", full_name: "owner/cok-yildiz",
                             html_url: "https://github.com/owner/cok-yildiz", stargazers_count: 99)

    get public_profile_path(owner)

    assert_response :success
    assert_match "cok-yildiz", response.body
    assert_match "az-yildiz", response.body
    # cok-yildiz (99) az-yildiz'dan (3) once gelmeli
    assert response.body.index("cok-yildiz") < response.body.index("az-yildiz")
  end

  test "gizlenen repo profilde gorunmez, gorunur olan gorunur" do
    owner = User.create!(name: "Gorunurluk Profil", provider: "github", uid: "pc-13", terms_accepted_at: Time.current)
    GithubRepository.create!(user: owner, name: "gorunen-repo", full_name: "owner/gorunen-repo",
                             html_url: "https://github.com/owner/gorunen-repo", stargazers_count: 5, visible_on_profile: true)
    GithubRepository.create!(user: owner, name: "gizli-repo", full_name: "owner/gizli-repo",
                             html_url: "https://github.com/owner/gizli-repo", stargazers_count: 5, visible_on_profile: false)

    get public_profile_path(owner)

    assert_response :success
    assert_match "gorunen-repo", response.body
    assert_no_match(/gizli-repo/, response.body)
  end

  test "profile guncellemede role mass-assignment ile degistirilemez" do
    user = User.create!(name: "Rol Testi", provider: "github", uid: "pc-8", role: "developer", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    patch profile_path, params: { user: { name: "Yeni İsim", bio: "Yeni bio", role: "admin" } }

    user.reload

    assert_equal "Yeni İsim", user.name
    assert_equal "Yeni bio", user.bio
    assert_not_equal "admin", user.role
    assert_equal "developer", user.role
  end

  test "profile guncellemede teaching_format ve availability_note kaydedilir" do
    user = User.create!(name: "Format Testi", provider: "github", uid: "pc-9", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    patch profile_path, params: { user: { teaching_format: "one_on_one", availability_note: "hafta ici aksamlari" } }

    user.reload

    assert_equal "one_on_one", user.teaching_format
    assert_equal "hafta ici aksamlari", user.availability_note
  end

  test "profile guncellemede banner_image dosyasi eklenir ve DB'ye persist edilir" do
    # Regresyon: orijinal bug'da upload sessizce basarisiz oluyor ama response
    # patlamiyordu. Bu test hem (a) beklenen redirect'i hem de (b) attachment'in
    # gercekten DB'ye yazildigini (reload sonrasi attached?) dogrular.
    user = User.create!(name: "Banner Testi", provider: "github", uid: "pc-banner-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    file = fixture_file_upload("banner_test_rgb.png", "image/png")
    patch profile_path, params: { user: { banner_image: file } }

    assert_redirected_to edit_profile_path
    assert user.reload.banner_image.attached?, "banner_image DB'de persist edilmis olmali"
    assert_equal "image/png", user.banner_image.content_type
  end

  test "cok buyuk banner yuklenince sayfa patlamadan hata gosterir" do
    # Regresyon: banner_image_must_be_valid validasyonu basarisiz oldugunda
    # ProfilesController#update, edit.html.erb'yi render ediyordu ama:
    #  1) @current_user.banner_image icin henuz persist edilmemis (invalid) bir
    #     attachment "attached?" true donduruyordu; image_tag bu blob icin
    #     signed_id uretmeye calisip "Cannot get a signed_id for a new record" ile patliyordu.
    #  2) edit action'da set edilen @teaching_skills/@learning_skills/@available_skills
    #     update action'da hic set edilmiyordu, bu da template'te NoMethodError'a yol aciyordu.
    user = User.create!(name: "Buyuk Banner", provider: "github", uid: "pc-banner-buyuk-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    big = Tempfile.new([ "big", ".png" ])
    big.write("\x89PNG\r\n\x1a\n")
    big.write("a" * 6.megabytes)
    big.rewind
    file = Rack::Test::UploadedFile.new(big.path, "image/png")

    patch profile_path, params: { user: { banner_image: file } }

    assert_response :unprocessable_entity
    assert_not user.reload.banner_image.attached?
  ensure
    big&.close!
  end

  test "yanlis content type ile banner yuklenince sayfa patlamadan hata gosterir" do
    user = User.create!(name: "Yanlis Tip Banner", provider: "github", uid: "pc-banner-tip-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    file = fixture_file_upload("banner_test_rgb.png", "text/plain")
    patch profile_path, params: {
    user: {
      banner_image: fixture_file_upload("test/fixtures/files/gecersiz_dosya.txt", "text/plain")
    }
  }

  assert_response :unprocessable_entity
    assert_not user.reload.banner_image.attached?
    # Kullaniciya gorunur bir hata banner'i render edilmeli (sessiz basarisizlik degil).
    assert_match "[HATA]", response.body
    assert_match(/geçerli bir görsel/, response.body)
  end

  test "banner kaldirma current_user'a scoped calisir ve attachment'i purge eder" do
    user = User.create!(name: "Banner Kaldirma", provider: "github", uid: "pc-banner-2", terms_accepted_at: Time.current)
    user.banner_image.attach(io: StringIO.new("fake-image"), filename: "banner.png", content_type: "image/png")
    sign_in_via_github(user)

    delete remove_profile_banner_path

    user.reload

    assert_redirected_to edit_profile_path
    assert_not user.banner_image.attached?
  end

  test "giris yapmamis kullanici banner kaldiramaz" do
    user = User.create!(name: "Giris Yok Banner", provider: "github", uid: "pc-banner-3", terms_accepted_at: Time.current)
    user.banner_image.attach(io: StringIO.new("fake-image"), filename: "banner.png", content_type: "image/png")

    delete remove_profile_banner_path

    assert user.reload.banner_image.attached?
  end

  test "banner eklenmis profilde banner gorseli gosterilir" do
    owner = User.create!(name: "Banner Gosterim", provider: "github", uid: "pc-banner-4", terms_accepted_at: Time.current)
    owner.banner_image.attach(io: StringIO.new("fake-image"), filename: "banner.png", content_type: "image/png")

    get public_profile_path(owner)

    assert_response :success
    assert_match "banner.png", response.body
  end

  test "banner eklenmemis profil sayfayi bozmadan gosterilir" do
    owner = User.create!(name: "Banner Yok", provider: "github", uid: "pc-banner-5", terms_accepted_at: Time.current)

    get public_profile_path(owner)

    assert_response :success
    assert_match owner.name, response.body
  end

  test "cevrimici kullanicinin profilinde Cevrimici gosterge gorunur" do
    owner = User.create!(name: "Cevrimici Profil", provider: "github", uid: "pc-online-1", terms_accepted_at: Time.current, is_online: true)

    get public_profile_path(owner)

    assert_response :success
    assert_match "Çevrimiçi", response.body
  end

  test "esleşmede olan (bitmemis DM'i olan) cevrimici kullanici Eslesmede gosterir" do
    owner = User.create!(name: "Eslesmede Profil", provider: "github", uid: "pc-online-2", terms_accepted_at: Time.current, is_online: true)
    peer = User.create!(name: "Eslesmede Karsi", provider: "github", uid: "pc-online-3", terms_accepted_at: Time.current)
    ChatRoom.find_or_create_dm_between(owner, peer)

    get public_profile_path(owner)

    assert_response :success
    assert_match "Eşleşmede", response.body
  end

  test "cevrimdisi ve last_seen_at set edilmis kullanici Son gorulme gosterir" do
    owner = User.create!(name: "Cevrimdisi Profil", provider: "github", uid: "pc-offline-1", terms_accepted_at: Time.current, is_online: false, last_seen_at: 2.hours.ago)

    get public_profile_path(owner)

    assert_response :success
    assert_match "Son görülme", response.body
  end

  test "hic gorulmemis kullanici Hic gorulmedi gosterir" do
    owner = User.create!(name: "Hic Gorulmemis Profil", provider: "github", uid: "pc-offline-2", terms_accepted_at: Time.current, is_online: false, last_seen_at: nil)

    get public_profile_path(owner)

    assert_response :success
    assert_match "Hiç görülmedi", response.body
  end

  test "profil ilk goruntulendiginde profil widget'lari lazy seed edilir" do
    owner = User.create!(name: "Seed Profil", provider: "github", uid: "pc-seed-1", terms_accepted_at: Time.current)
    assert_equal 0, ProfileWidget.where(user: owner).count

    get public_profile_path(owner)

    assert_response :success
    assert_equal ProfileWidget::WIDGET_TYPES.length, ProfileWidget.where(user: owner).count
  end

  test "sahip kendi profiline bakinca Duzenle butonu ve profile-grid controller gorunur" do
    owner = User.create!(name: "Duzenleyen Sahip", provider: "github", uid: "pc-owner-1", terms_accepted_at: Time.current)
    sign_in_via_github(owner)

    get public_profile_path(owner)

    assert_response :success
    assert_match "Düzenle", response.body
    assert_match "profile-grid", response.body
  end

  test "ziyaretci baskasinin profilinde Duzenle butonu veya edit chrome gormez" do
    owner = User.create!(name: "Salt Okunur Sahip", provider: "github", uid: "pc-owner-2", terms_accepted_at: Time.current)
    viewer = User.create!(name: "Salt Okunur Ziyaretci", provider: "github", uid: "pc-viewer-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get public_profile_path(owner)

    assert_response :success
    # Sahip olmayan ziyaretci edit araç çubuğunu ve widget başına edit chrome'unu
    # (Gizle/A±) GÖRMEZ — ızgara salt-okunur.
    assert_no_match(/Düzenle/, response.body)
    assert_no_match(/profile-grid#hideWidget/, response.body)
    # Ancak controller ve izgara YİNE DE render edilir: Gridstack olmadan
    # widget'lar üst üste yığılırdı (Bug 1). Bu yüzden salt-okunur ziyaretçide
    # bile controller eklenir; edit yeteneği markup düzeyinde kapatılır.
    assert_match(/data-controller="profile-grid"/, response.body)
    assert_match "grid-stack", response.body
  end

  test "giris yapmamis ziyaretci profil izgarasini salt-okunur gorur (edit chrome yok)" do
    owner = User.create!(name: "Anonim Salt Okunur", provider: "github", uid: "pc-owner-3", terms_accepted_at: Time.current)

    get public_profile_path(owner)

    assert_response :success
    assert_no_match(/Düzenle/, response.body)
    assert_no_match(/profile-grid#hideWidget/, response.body)
    # Izgara ve controller yine de render edilmeli (Gridstack konumlandırması
    # olmadan widget'lar iç içe geçerdi).
    assert_match(/data-controller="profile-grid"/, response.body)
    assert_match "grid-stack", response.body
  end

  test "profil izgarasindaki gorunur widget'lar farkli (cakismayan) gs-x/gs-y konumlarina sahiptir" do
    owner = User.create!(name: "Konum Profil", provider: "github", uid: "pc-pos-1", terms_accepted_at: Time.current)

    get public_profile_path(owner)

    assert_response :success

    # Her grid-stack-item'in gs-x/gs-y/gs-w/gs-h dörtlüsünü çıkar.
    boxes = response.body.scan(/gs-x="(\d+)"\s+gs-y="(\d+)"\s+gs-w="(\d+)"\s+gs-h="(\d+)"/).map do |x, y, w, h|
      { x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i }
    end

    assert_operator boxes.length, :>=, 2, "en az iki görünür widget beklenir"

    # Hicbir iki kutu birbiriyle ortusmemeli (sinir kutusu kesisimi bos olmali).
    boxes.combination(2).each do |a, b|
      overlap_x = a[:x] < b[:x] + b[:w] && b[:x] < a[:x] + a[:w]
      overlap_y = a[:y] < b[:y] + b[:h] && b[:y] < a[:y] + a[:h]
      assert_not(overlap_x && overlap_y, "widget kutuları çakışıyor: #{a.inspect} vs #{b.inspect}")
    end

    # Her widget 12 kolonluk ızgara icinde kalmali.
    boxes.each do |bx|
      assert_operator bx[:x] + bx[:w], :<=, 12, "widget ızgara sınırını aşıyor: #{bx.inspect}"
    end
  end

  # --- Blok: stalk-onleme (yonlu profil goruntuleme kisitlamasi) ---

  test "engellenen kullanici, engelleyenin profilini goremez" do
    blocker = User.create!(name: "Engelleyen Sahip", provider: "github", uid: "pc-bl-1", terms_accepted_at: Time.current)
    blocked = User.create!(name: "Engellenen Ziyaretci", provider: "github", uid: "pc-bl-2", terms_accepted_at: Time.current)
    blocker.blocks_made.create!(blocked: blocked)
    sign_in_via_github(blocked)

    get public_profile_path(blocker)

    assert_redirected_to root_path
    assert_equal "Bu profili görüntüleyemezsin.", flash[:alert]
  end

  test "engelleyen kullanici, engelledigi kisinin profilini gorebilir (yonlu)" do
    blocker = User.create!(name: "Engelleyen Ziyaretci", provider: "github", uid: "pc-bl-3", terms_accepted_at: Time.current)
    blocked = User.create!(name: "Engellenen Sahip", provider: "github", uid: "pc-bl-4", terms_accepted_at: Time.current)
    blocker.blocks_made.create!(blocked: blocked)
    sign_in_via_github(blocker)

    get public_profile_path(blocked)

    assert_response :success
    assert_match blocked.name, response.body
  end

  test "takipci ve takip sayilari profilde gorunur" do
    owner = User.create!(name: "Sayac Sahip", provider: "github", uid: "pc-fc-1", terms_accepted_at: Time.current)
    fan = User.create!(name: "Sayac Fan", provider: "github", uid: "pc-fc-2", terms_accepted_at: Time.current)
    fan.active_follows.create!(followee: owner)

    get public_profile_path(owner)

    assert_response :success
    assert_match "takipçi", response.body
    assert_match "takip", response.body
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
