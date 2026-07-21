require "test_helper"

class PostSharesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end

  def user!(uid)
    User.create!(name: "PS-#{uid}", provider: "github", uid: uid, terms_accepted_at: Time.current)
  end

  test "gonderme bir PostShare kaydi VE bir DM mesaji olusturur" do
    sender = user!("psc-1")
    recipient = user!("psc-2")
    ChatRoom.find_or_create_dm_between(sender, recipient)
    p = Post.create!(content: "paylasilacak icerik", user: sender)
    sign_in_via_github(sender)

    assert_difference [ "PostShare.count", "Message.count" ], 1 do
      post share_post_path(p), params: { recipient_id: recipient.id, message: "sana uygun" }
    end

    room = ChatRoom.find_or_create_dm_between(sender, recipient)
    assert room.messages.exists?, "DM odasina mesaj birakilmali"
    assert_match "sana uygun", room.messages.last.body
  end

  test "kendine gonderilemez" do
    sender = user!("psc-3")
    p = Post.create!(content: "x", user: sender)
    sign_in_via_github(sender)

    assert_no_difference "PostShare.count" do
      post share_post_path(p), params: { recipient_id: sender.id }
    end
  end

  test "giris gerektirir" do
    sender = user!("psc-4")
    recipient = user!("psc-5")
    p = Post.create!(content: "x", user: sender)

    assert_no_difference "PostShare.count" do
      post share_post_path(p), params: { recipient_id: recipient.id }
    end
    assert_redirected_to root_path
  end

  test "share_targets yalnizca current_user'in kendi DM partnerlerini doner" do
    me = user!("psc-6")
    partner = user!("psc-7")
    stranger = user!("psc-8")
    ChatRoom.find_or_create_dm_between(me, partner)
    p = Post.create!(content: "x", user: me)
    sign_in_via_github(me)

    get post_share_targets_path(p)
    assert_response :success
    assert_match partner.name, response.body
    assert_no_match(/#{stranger.name}/, response.body)
  end

  test "share_targets `q` parametresini yok sayar ve DAHA ONCE DM YAPILMAMIS kullaniciyi ASLA dondurmez" do
    # Arama artik tamamen client-side; sunucu `q` parametresi verilse bile
    # yalnizca mevcut DM partnerlerini doner. Hic DM'i olmayan kullaniciya
    # post-paylasim uzerinden ulasilamamali.
    me = user!("psc-search-me")
    never_dmed = User.create!(name: "Zephyr Unique", provider: "github",
                              uid: "psc-search-target", terms_accepted_at: Time.current)
    p = Post.create!(content: "x", user: me)
    sign_in_via_github(me)

    get post_share_targets_path(p), params: { q: "zephyr" }
    assert_response :success
    assert_no_match(/#{never_dmed.name}/, response.body)
  end

  test "share_targets arama sonucunda kullanici kendini gormez" do
    me = user!("psc-self")
    p = Post.create!(content: "x", user: me)
    sign_in_via_github(me)

    get post_share_targets_path(p), params: { q: "PS-psc-self" }
    assert_response :success
    assert_no_match(/PS-psc-self/, response.body)
  end

  test "uctan uca: hic DM'i olmayan birine post GONDERILEMEZ (sunucu reddeder)" do
    sender = user!("psc-e2e-1")
    fresh_recipient = User.create!(name: "Yeni Kisi", provider: "github",
                                   uid: "psc-e2e-2", terms_accepted_at: Time.current)
    p = Post.create!(content: "keşfedilecek post", user: sender)
    sign_in_via_github(sender)

    # 1) share_targets listesinde hic gorunmez (DM partneri degil).
    get post_share_targets_path(p)
    assert_response :success
    assert_no_match(/#{fresh_recipient.name}/, response.body)

    # 2) Dogrudan API cagrisiyla denese bile sunucu reddeder, DM mesaji OLUSMAZ.
    assert_no_difference [ "PostShare.count", "Message.count" ] do
      post share_post_path(p), params: { recipient_id: fresh_recipient.id, message: "buna bak" }
    end

    assert_response :redirect
  end

  test "gonderim turbo_stream ile etkilesim cubugunu tazeler ve toast dondurur" do
    sender = user!("psc-ts-1")
    recipient = user!("psc-ts-2")
    ChatRoom.find_or_create_dm_between(sender, recipient)
    p = Post.create!(content: "x", user: sender)
    sign_in_via_github(sender)

    post share_post_path(p),
         params: { recipient_id: recipient.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "post_#{p.id}_interactions", response.body
    assert_match "gönderildi", response.body
  end

  test "GIZLILIK: share_targets bir postun PostShare alicilarini SIZDIRMAZ" do
    # A postu C'ye gonderir. B (A'nin partneri) share_targets istedginde,
    # C B'nin partneri olmadigi icin B'nin listesinde GORUNMEMELI.
    a = user!("psc-a")
    b = user!("psc-b")
    c = user!("psc-c")
    ChatRoom.find_or_create_dm_between(a, b)
    p = Post.create!(content: "gizli", user: a)
    PostShare.create!(user: a, post: p, recipient: c)

    sign_in_via_github(b)
    get post_share_targets_path(p)
    assert_response :success
    assert_no_match(/#{c.name}/, response.body)
  end
end
