require "test_helper"

class TerminalChatChannelTest < ActionCable::Channel::TestCase
  # Kanal artik yetkilendirme icin connection.current_user'i okuyor; genel odalarda
  # bu deger onemsiz (participant? her zaman true) ama connection'in kimlige sahip
  # olmasi gerekiyor. Varsayilan olarak bir kullaniciyla baglantiyi stub'liyoruz.
  setup { stub_connection(current_user: users(:one)) }

  test "kullanici kanala abone olabilir ve oda-ozel stream'e baglanir" do
    subscribe user: "Ada Lovelace", room: "genel"

    assert subscription.confirmed?
    assert_has_stream "terminal_chat_channel_genel"
  end

  test "room parametresi verilmezse varsayilan genel odasina abone olunur" do
    subscribe user: "Ada Lovelace"

    assert subscription.confirmed?
    assert_has_stream "terminal_chat_channel_genel"
  end

  test "farkli oda slug'i icin oda-ozel stream'e abone olunur" do
    subscribe user: "Ada Lovelace", room: "backend"

    assert subscription.confirmed?
    assert_has_stream "terminal_chat_channel_backend"
  end

  test "user parametresi verildiginde kisiye ozel feed stream'ine de abone olunur" do
    subscribe user: "Ada Lovelace", room: "genel"

    assert_has_stream "user_Ada Lovelace_feed"
  end

  test "user parametresi bos ise kisiye ozel feed stream'ine abone olunmaz" do
    subscribe user: "", room: "genel"

    assert subscription.confirmed?
    assert_has_stream "terminal_chat_channel_genel"
    assert_has_no_stream "user__feed"
  end

  test "typing action'i dogru kullanici verisiyle oda-ozel kanala broadcast yapar" do
    subscribe user: "Alan Turing", room: "backend"

    assert_broadcast_on("terminal_chat_channel_backend", type: "typing", user: "Alan Turing") do
      perform :typing, user: "Alan Turing", room: "backend"
    end
  end

  test "typing action'i room verilmezse genel kanala broadcast yapar" do
    subscribe user: "Alan Turing"

    assert_broadcast_on("terminal_chat_channel_genel", type: "typing", user: "Alan Turing") do
      perform :typing, user: "Alan Turing"
    end
  end

  test "typing action'i debounce penceresi icinde tekrar broadcast yapmaz" do
    # Test ortaminda cache_store :null_store oldugu icin debounce'u gercekten
    # dogrulayabilmek adina gecici olarak gercek bir MemoryStore kullaniyoruz.
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    subscribe user: "Alan Turing", room: "genel"

    assert_broadcast_on("terminal_chat_channel_genel", type: "typing", user: "Alan Turing") do
      perform :typing, user: "Alan Turing", room: "genel"
    end

    assert_no_broadcasts("terminal_chat_channel_genel") do
      perform :typing, user: "Alan Turing", room: "genel"
    end
  ensure
    Rails.cache = original_cache
  end

  test "typing action'i user bos ise broadcast yapmaz" do
    subscribe user: "Ada Lovelace", room: "genel"

    assert_no_broadcasts("terminal_chat_channel_genel") do
      perform :typing, user: "", room: "genel"
    end
  end

  # --- Faz 14: Ozel (DM) oda yetkilendirmesi (EN KRITIK) ---

  test "katilimci olmayan kullanici private oda stream'ine abone olamaz (REDDEDILIR)" do
    owner = User.create!(name: "Kanal DM Sahibi", provider: "github", uid: "ch-owner", terms_accepted_at: Time.current)
    peer = User.create!(name: "Kanal DM Karsi", provider: "github", uid: "ch-peer", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    outsider = User.create!(name: "Kanal Yabanci", provider: "github", uid: "ch-out", terms_accepted_at: Time.current)
    stub_connection(current_user: outsider)

    subscribe room: dm.slug

    assert subscription.rejected?
    assert_has_no_stream "terminal_chat_channel_#{dm.slug}"
  end

  test "katilimci private oda stream'ine abone olabilir" do
    owner = User.create!(name: "Kanal DM Ic", provider: "github", uid: "ch-in", terms_accepted_at: Time.current)
    peer = User.create!(name: "Kanal DM Ic 2", provider: "github", uid: "ch-in2", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    stub_connection(current_user: owner)

    subscribe room: dm.slug

    assert subscription.confirmed?
    assert_has_stream "terminal_chat_channel_#{dm.slug}"
  end

  test "current_user nil ise private oda stream'ine abone olunamaz" do
    owner = User.create!(name: "Kanal Nil Sahibi", provider: "github", uid: "ch-nil-owner", terms_accepted_at: Time.current)
    peer = User.create!(name: "Kanal Nil Karsi", provider: "github", uid: "ch-nil-peer", terms_accepted_at: Time.current)
    dm = ChatRoom.find_or_create_dm_between(owner, peer)

    stub_connection(current_user: nil)

    subscribe room: dm.slug

    assert subscription.rejected?
  end

  # --- Faz 24: mark_read action'i ---

  test "mark_read action'i mesaji okundu isaretler ve read_receipt yayinlar" do
    sender = User.create!(name: "Okundu Gonderen", provider: "github", uid: "ch-read-1", terms_accepted_at: Time.current)
    room = ChatRoom.create!(name: "Genel", slug: "genel-read-test", private: false)
    message = Message.create!(user: sender, chat_room: room, body: "Merhaba")

    subscribe user: "Okundu Gonderen", room: room.slug

    assert_broadcast_on("terminal_chat_channel_#{room.slug}", type: "read_receipt", message_id: message.id) do
      perform :mark_read, message_id: message.id
    end

    assert message.reload.read_at.present?
  end

  test "mark_read action'i zaten okunmus mesaj icin tekrar broadcast yapmaz" do
    sender = User.create!(name: "Okundu Gonderen 2", provider: "github", uid: "ch-read-2", terms_accepted_at: Time.current)
    room = ChatRoom.create!(name: "Genel", slug: "genel-read-test-2", private: false)
    message = Message.create!(user: sender, chat_room: room, body: "Merhaba", read_at: Time.current)

    subscribe user: "Okundu Gonderen 2", room: room.slug

    assert_no_broadcasts("terminal_chat_channel_#{room.slug}") do
      perform :mark_read, message_id: message.id
    end
  end

  test "mark_read action'i var olmayan mesaj_id icin hata firlatmaz" do
    subscribe user: "Ada Lovelace", room: "genel"

    assert_no_broadcasts("terminal_chat_channel_genel") do
      perform :mark_read, message_id: -1
    end
  end
end
