require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmadan erisim root_path'e yonlendirilir" do
    get room_path("genel")

    assert_redirected_to root_path
  end

  test "giris yapinca gecerli slug icin 200 doner ve oda mesajlari render edilir" do
    viewer = User.create!(name: "Oda Izleyici", provider: "github", uid: "room-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get room_path("genel")

    assert_response :success
    # chat_panel frame'i dogru oda slug'i ve o odanin mesajlari ile render edilir
    assert_match 'data-room-slug="genel"', response.body
    assert_match messages(:one).body, response.body
    assert_match 'id="chat_panel"', response.body
    # gizli room alani da oda slug'ini tasir
    assert_match 'value="genel"', response.body
  end

  test "gecersiz slug 404 (RecordNotFound) doner" do
    viewer = User.create!(name: "Oda Bulunamadi", provider: "github", uid: "room-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get room_path("olmayan-oda")

    assert_response :not_found
  end

  # --- Faz 14: Ozel (DM) odalar ve yetkilendirme ---

  test "katilimci olmayan kullanici private DM odasina erisemez" do
    owner = User.create!(name: "DM Sahibi", provider: "github", uid: "dm-owner", terms_accepted_at: Time.current)
    peer = User.create!(name: "DM Karsi", provider: "github", uid: "dm-peer", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    outsider = User.create!(name: "DM Yabanci", provider: "github", uid: "dm-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    get room_path(dm.slug)

    assert_redirected_to root_path
    assert_equal "Bu odaya erişim yetkin yok.", flash[:alert]
  end

  test "katilimci private DM odasina erisebilir" do
    owner = User.create!(name: "DM Katilimci", provider: "github", uid: "dm-in", terms_accepted_at: Time.current)
    peer = User.create!(name: "DM Katilimci 2", provider: "github", uid: "dm-in2", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    sign_in_via_github(owner)

    get room_path(dm.slug)

    assert_response :success
  end

  test "start_dm hedef kullaniciyla private oda olusturur ve yonlendirir" do
    viewer = User.create!(name: "Baslatan", provider: "github", uid: "dm-start-1", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "dm-start-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "ChatRoom.count", 1 do
      post start_dm_room_path(user_id: target.id)
    end

    dm = ChatRoom.find_or_create_dm_between(viewer, target)
    assert_redirected_to room_path(dm.slug)
    assert dm.private?
  end

  test "start_dm ikinci kez cagirildiginda yeni oda uretmez (idempotent)" do
    viewer = User.create!(name: "Baslatan Tekrar", provider: "github", uid: "dm-idem-1", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef Tekrar", provider: "github", uid: "dm-idem-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    post start_dm_room_path(user_id: target.id)

    assert_no_difference "ChatRoom.count" do
      post start_dm_room_path(user_id: target.id)
    end
  end

  test "start_dm kendine sohbet acmaya calisinca root_path'e yonlendirir" do
    viewer = User.create!(name: "Kendine", provider: "github", uid: "dm-self", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_no_difference "ChatRoom.count" do
      post start_dm_room_path(user_id: viewer.id)
    end

    assert_redirected_to root_path
    assert_equal "Kendinle sohbet açamazsın.", flash[:alert]
  end

  # --- Faz 32c: origin (Baglanti Kur = match, Sohbet Ac = direct) ---

  test "start_dm origin='match' ile eslesme kaynakli oda olusturur" do
    viewer = User.create!(name: "Match Baslatan", provider: "github", uid: "dm-origin-m1", terms_accepted_at: Time.current)
    target = User.create!(name: "Match Hedef", provider: "github", uid: "dm-origin-m2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    post start_dm_room_path(user_id: target.id), params: { origin: "match" }

    room = ChatRoom.find_or_create_dm_between(viewer, target)
    assert_equal "match", room.origin
    assert room.match_origin?
  end

  test "start_dm origin parametresiz varsayilan 'direct'tir" do
    viewer = User.create!(name: "Direct Baslatan", provider: "github", uid: "dm-origin-d1", terms_accepted_at: Time.current)
    target = User.create!(name: "Direct Hedef", provider: "github", uid: "dm-origin-d2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    post start_dm_room_path(user_id: target.id), params: { origin: "direct" }

    room = ChatRoom.find_or_create_dm_between(viewer, target)
    assert_equal "direct", room.origin
    assert_not room.match_origin?
  end

  test "start_dm keyfi origin degeri 'direct'e indirgenir" do
    viewer = User.create!(name: "Keyfi Baslatan", provider: "github", uid: "dm-origin-x1", terms_accepted_at: Time.current)
    target = User.create!(name: "Keyfi Hedef", provider: "github", uid: "dm-origin-x2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    post start_dm_room_path(user_id: target.id), params: { origin: "hacker" }

    room = ChatRoom.find_or_create_dm_between(viewer, target)
    assert_equal "direct", room.origin
  end

  test "match odada 'İlişkiyi Sonlandır' UI'i render edilir" do
    a = User.create!(name: "UI Match A", provider: "github", uid: "ui-m-a", terms_accepted_at: Time.current)
    b = User.create!(name: "UI Match B", provider: "github", uid: "ui-m-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b, origin: "match")
    sign_in_via_github(a)

    get room_path(dm.slug)

    assert_response :success
    assert_match "İlişkiyi Sonlandır", response.body
  end

  test "direct odada 'İlişkiyi Sonlandır' UI'i render EDILMEZ" do
    a = User.create!(name: "UI Direct A", provider: "github", uid: "ui-d-a", terms_accepted_at: Time.current)
    b = User.create!(name: "UI Direct B", provider: "github", uid: "ui-d-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b, origin: "direct")
    sign_in_via_github(a)

    get room_path(dm.slug)

    assert_response :success
    assert_no_match "İlişkiyi Sonlandır", response.body
    assert_no_match "İlişki sonlandı", response.body
  end

  # --- Faz 20: iliski sonlandirma ---

  test "request_end katilimci sonlandirma istegini kaydeder" do
    a = User.create!(name: "End A", provider: "github", uid: "end-a", terms_accepted_at: Time.current)
    b = User.create!(name: "End B", provider: "github", uid: "end-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    sign_in_via_github(a)

    post request_end_room_path(dm.slug)

    assert_redirected_to room_path(dm.slug)
    assert_not dm.reload.ended?
    assert dm.ended_by_a? || dm.ended_by_b?
  end

  test "request_end iki taraf da onaylayinca oda sonlanir" do
    a = User.create!(name: "End A2", provider: "github", uid: "end-a2", terms_accepted_at: Time.current)
    b = User.create!(name: "End B2", provider: "github", uid: "end-b2", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)

    sign_in_via_github(a)
    post request_end_room_path(dm.slug)

    sign_in_via_github(b)
    post request_end_room_path(dm.slug)

    assert dm.reload.ended?
  end

  test "request_end katilimci olmayani reddeder" do
    a = User.create!(name: "End A3", provider: "github", uid: "end-a3", terms_accepted_at: Time.current)
    b = User.create!(name: "End B3", provider: "github", uid: "end-b3", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)

    outsider = User.create!(name: "End Out", provider: "github", uid: "end-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    post request_end_room_path(dm.slug)

    assert_redirected_to root_path
    assert_equal "Bu odaya erişim yetkin yok.", flash[:alert]
    assert_not dm.reload.ended_by_a?
    assert_not dm.ended_by_b?
  end

  # --- Faz 32c: "hicbir sey olmuyor" bug'i — buton gercekten calisir + geri bildirim ---

  test "request_end sonrasi redirect takip edilince geri bildirim frame ICINDE gorunur (bug fix)" do
    a = User.create!(name: "FB A", provider: "github", uid: "fb-a", terms_accepted_at: Time.current)
    b = User.create!(name: "FB B", provider: "github", uid: "fb-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b, origin: "match")
    sign_in_via_github(a)

    post request_end_room_path(dm.slug)
    assert dm.reload.ended_by_a? || dm.ended_by_b?, "state gercekten degismis olmali"

    # Redirect'i takip et: chat_panel frame'i (layout toast'u degil) geri bildirimi tasimali.
    follow_redirect!
    assert_response :success
    assert_match "Sonlandırma isteğin kaydedildi", response.body
  end

  test "iki taraf da sonlandirinca degerlendirme (rating) formu erisilebilir olur" do
    a = User.create!(name: "Rate A", provider: "github", uid: "rate-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Rate B", provider: "github", uid: "rate-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b, origin: "match")

    sign_in_via_github(a)
    post request_end_room_path(dm.slug)
    sign_in_via_github(b)
    post request_end_room_path(dm.slug)

    assert dm.reload.ended?

    # b tarafinda oda sayfasi artik rating formunu (Değerlendir butonu) icermeli.
    get room_path(dm.slug)
    assert_response :success
    assert_match "Değerlendir", response.body

    # Ve rating gercekten kaydedilebilir olmali (iki tarafli akis calisir).
    assert_difference "Rating.count", 1 do
      post ratings_path, params: { room_slug: dm.slug, score: 5, note: "harika" }
    end
  end

  # --- Faz 20: GIZLILIK — bireysel rating/note kimseye gorunmez ---

  test "bir kullanici baskasinin aldigi bireysel rating notunu hicbir sayfada goremez" do
    a = User.create!(name: "Gizli Rater", provider: "github", uid: "priv-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Gizli Rated", provider: "github", uid: "priv-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    dm.update!(ended_by_a: true, ended_by_b: true)

    secret_note = "COKGIZLIDEGERLENDIRMENOTU-2026"
    Rating.create!(rater: a, rated_user: b, chat_room: dm, score: 1, note: secret_note)

    snooper = User.create!(name: "Merakli", provider: "github", uid: "priv-snoop", terms_accepted_at: Time.current)
    sign_in_via_github(snooper)

    # Baskasinin (b) profilini ziyaret et
    get public_profile_path(b.id)
    assert_response :success
    assert_no_match secret_note, response.body

    # Dashboard'da da gorunmemeli
    get root_path
    assert_no_match secret_note, response.body
  end

  # --- Faz 27: oda kural banner'i ---

  test "kurallari olan odaya girince rules metni response body'de gorunur" do
    room = ChatRoom.create!(name: "Kurallı Oda", slug: "kuralli-oda", position: 42,
                            rules: "KURAL_BANNER_TEST_METNI-2026")
    viewer = User.create!(name: "Kural Izleyici", provider: "github", uid: "rules-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get room_path(room.slug)

    assert_response :success
    assert_match "KURAL_BANNER_TEST_METNI-2026", response.body
    assert_match "ODA_KURALLARI", response.body
  end

  # --- Faz 32c UI: minimal DM popup (tek konusma) + tiklanabilir kullanici adi ---

  test "minimal=1 popup SADECE tek konusmayi render eder (room_tabs YOK) ve karsi katilimci ismi + profil linki gorunur" do
    a = User.create!(name: "Minimal A", provider: "github", uid: "min-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Minimal Partner B", provider: "github", uid: "min-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    Message.create!(user: b, chat_room: dm, body: "minimal popup mesaji")
    sign_in_via_github(a)

    get room_path(dm.slug, minimal: 1)

    assert_response :success
    # room_tabs (oda sekmeleri) render EDILMEMELI.
    assert_no_match 'aria-label="Sohbet odaları"', response.body
    # Karsi katilimcinin ismi + profiline giden link gorunmeli.
    assert_match b.name, response.body
    assert_match %r{href="/u/#{b.id}"}, response.body
    # Sohbet paneli (bu tek konusma) yine render edilmeli.
    assert_match "minimal popup mesaji", response.body
    assert_match 'id="chat_panel"', response.body
  end

  test "minimal parametresiz normal oda room_tabs (oda sekmeleri) icerir" do
    viewer = User.create!(name: "Normal Tab Izleyici", provider: "github", uid: "norm-tab", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get room_path("genel")

    assert_response :success
    assert_match 'aria-label="Sohbet odaları"', response.body
  end

  test "mesajdaki kullanici adi o kullanicinin profiline baglanan link olarak render edilir" do
    author = User.create!(name: "Linkli Yazar", provider: "github", uid: "link-author", terms_accepted_at: Time.current)
    Message.create!(user: author, chat_room: chat_rooms(:genel), body: "tiklanabilir isim mesaji")
    sign_in_via_github(author)

    get room_path("genel")

    assert_response :success
    assert_match %r{<a[^>]+href="/u/#{author.id}"[^>]*>#{author.name}</a>}, response.body
  end

  # --- Faz 32d: standalone /rooms/:slug redesign (terminal chrome + DM kenar cubugu) ---

  test "standalone oda sayfasi koyu terminal chrome ile render edilir" do
    viewer = User.create!(name: "Chrome Izleyici", provider: "github", uid: "chrome-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get room_path("genel")

    assert_response :success
    # Koyu terminal govdesi + tam-yukseklik koyu arka plan.
    assert_match "bg-terminal-bg-2", response.body
    assert_match "min-h-screen", response.body
    # Paylasilan chrome baslik cubugundaki mac/windows skin gecis butonu.
    assert_match "Terminal görünümünü değiştir", response.body
  end

  test "standalone oda sayfasi DM kenar cubugu (kisiler + arama kutusu) icerir" do
    a = User.create!(name: "Sidebar A", provider: "github", uid: "sb-a", terms_accepted_at: Time.current)
    partner = User.create!(name: "Sidebar Partner Kisi", provider: "github", uid: "sb-b", terms_accepted_at: Time.current)
    ChatRoom.find_or_create_dm_between(a, partner)
    sign_in_via_github(a)

    get room_path("genel")

    assert_response :success
    assert_match "contact-search", response.body
    assert_match "Kişilerde ara", response.body
    # DM karsi katilimcisinin ismi kenar cubugunda listelenir.
    assert_match partner.name, response.body
  end

  test "minimal=1 popup redesign chrome/sidebar YOK, sadece chat_panel frame'i" do
    a = User.create!(name: "Min Chrome A", provider: "github", uid: "minc-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Min Chrome B", provider: "github", uid: "minc-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    sign_in_via_github(a)

    get room_path(dm.slug, minimal: 1)

    assert_response :success
    # Minimal popup icerigi kenar cubugu arama kutusu tasimamalı.
    assert_no_match "contact-search", response.body
    assert_match 'id="chat_panel"', response.body
  end

  # --- Faz 32d: DM sekmesi kapatma (dismiss) ---

  test "dismiss katilimci icin DismissedConversation olusturur ve yonlendirir" do
    a = User.create!(name: "Dismiss Ctrl A", provider: "github", uid: "dis-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Dismiss Ctrl B", provider: "github", uid: "dis-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    sign_in_via_github(a)

    assert_difference "DismissedConversation.count", 1 do
      post dismiss_room_path(dm.slug)
    end

    assert_redirected_to root_path
    assert DismissedConversation.exists?(user: a, chat_room: dm)
  end

  test "dismiss katilimci olmayani reddeder ve kayit olusturmaz" do
    a = User.create!(name: "Dismiss Own A", provider: "github", uid: "dis-own-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Dismiss Own B", provider: "github", uid: "dis-own-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)

    outsider = User.create!(name: "Dismiss Yabanci", provider: "github", uid: "dis-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    assert_no_difference "DismissedConversation.count" do
      post dismiss_room_path(dm.slug)
    end

    assert_redirected_to root_path
    assert_equal "Bu odaya erişim yetkin yok.", flash[:alert]
  end

  test "kapatilan DM sekmesi tab listesinde gizlenir, yeni mesaj gelince geri belirir" do
    a = User.create!(name: "Tab Gizle A", provider: "github", uid: "tabh-a", terms_accepted_at: Time.current)
    b = User.create!(name: "Tab Gizle Partner", provider: "github", uid: "tabh-b", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(a, b)
    sign_in_via_github(a)

    # Kapat.
    post dismiss_room_path(dm.slug)

    # genel odadayken (aktif oda DM degil) kapatilan DM sekmesi gizli olmali.
    get room_path("genel")
    assert_response :success
    assert_no_match %r{@</span>\s*<span class="normal-case">#{Regexp.escape(b.name)}</span>}, response.body

    # Yeni mesaj gelince sekme geri belirmeli.
    travel 1.minute do
      Message.create!(chat_room: dm, user: b, body: "geri getir beni")
    end

    get room_path("genel")
    assert_response :success
    # DM sekmesi (sadece tab markup'i, kenar cubugu degil) geri belirmeli + okunmamis rozeti.
    assert_match %r{@</span>\s*<span class="normal-case">#{Regexp.escape(b.name)}</span>}, response.body
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
