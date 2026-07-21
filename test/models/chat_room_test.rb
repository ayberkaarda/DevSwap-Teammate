require "test_helper"

class ChatRoomTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "gecerli name ve benzersiz slug ile gecerlidir" do
    room = ChatRoom.new(name: "Backend", slug: "backend", position: 1)
    assert room.valid?
  end

  test "name olmadan gecersizdir" do
    room = ChatRoom.new(slug: "bos-isim")
    assert_not room.valid?
    assert_includes room.errors[:name], "can't be blank"
  end

  test "slug olmadan gecersizdir" do
    room = ChatRoom.new(name: "Isimli")
    assert_not room.valid?
    assert_includes room.errors[:slug], "can't be blank"
  end

  test "slug benzersiz olmalidir" do
    ChatRoom.create!(name: "Genel Iki", slug: "genel-iki", position: 5)
    duplicate = ChatRoom.new(name: "Baska", slug: "genel-iki")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "has_many messages iliskisine sahiptir" do
    assert_equal [ messages(:one), messages(:two) ].sort_by(&:id),
                 chat_rooms(:genel).messages.order(:id).to_a
  end

  test "oda silinince mesajlari da silinir (dependent: :destroy)" do
    room = ChatRoom.create!(name: "Gecici", slug: "gecici", position: 9)
    room.messages.create!(user: users(:one), body: "gecici mesaj")

    assert_difference "Message.count", -1 do
      room.destroy
    end
  end

  # --- Faz 14: Ozel (DM) odalar ---

  test "find_or_create_dm_between iki kullanici icin private oda olusturur" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert room.private?
    assert_equal "Özel Mesaj", room.name
    lower, higher = [ users(:one), users(:two) ].sort_by(&:id)
    assert_equal lower, room.user_a
    assert_equal higher, room.user_b
    assert_equal "dm-#{lower.id}-#{higher.id}", room.slug
  end

  test "find_or_create_dm_between kullanici sirasindan bagimsiz ayni odayi dondurur (normalizasyon)" do
    first = ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    second = ChatRoom.find_or_create_dm_between(users(:two), users(:one))

    assert_equal first.id, second.id
  end

  test "find_or_create_dm_between idempotenttir, ikinci cagri yeni oda uretmez" do
    ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert_no_difference "ChatRoom.count" do
      ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    end
  end

  test "find_or_create_dm_between ayni kullanici icin ArgumentError firlatir" do
    assert_raises(ArgumentError) do
      ChatRoom.find_or_create_dm_between(users(:one), users(:one))
    end
  end

  test "participant? genel odada herkes icin true doner" do
    assert chat_rooms(:genel).participant?(users(:one))
    assert chat_rooms(:genel).participant?(nil)
  end

  test "participant? private odada yalnizca katilimcilar icin true doner" do
    outsider = User.create!(name: "Yabanci", provider: "github", uid: "cr-out", terms_accepted_at: Time.current)
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert room.participant?(users(:one))
    assert room.participant?(users(:two))
    assert_not room.participant?(outsider)
    assert_not room.participant?(nil)
  end

  test "display_name_for genel odada oda adini doner" do
    assert_equal "Genel", chat_rooms(:genel).display_name_for(users(:one))
  end

  test "display_name_for private odada karsi tarafin adini doner" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert_equal users(:two).name, room.display_name_for(users(:one))
    assert_equal users(:one).name, room.display_name_for(users(:two))
  end

  # --- Faz 20: iliski sonlandirma ve degerlendirme ---

  test "request_end! genel odada calismaz (private degil)" do
    assert_equal false, chat_rooms(:genel).request_end!(users(:one))
    assert_not chat_rooms(:genel).ended?
  end

  test "request_end! katilimci olmayan icin calismaz" do
    outsider = User.create!(name: "Son Yabanci", provider: "github", uid: "cr-end-out", terms_accepted_at: Time.current)
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert_equal false, room.request_end!(outsider)
    assert_not room.ended?
  end

  test "tek taraf sonlandirinca ended? false, ikisi de sonlandirinca true" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    room.request_end!(users(:one))
    assert_not room.ended?

    room.request_end!(users(:two))
    assert room.ended?
  end

  test "request_end! dogru tarafin bayragini set eder" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    a = room.user_a
    b = room.user_b

    room.request_end!(a)
    assert room.reload.ended_by_a?
    assert_not room.ended_by_b?

    room.request_end!(b)
    assert room.reload.ended_by_b?
  end

  test "other_participant karsi tarafi doner, genel odada nil" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))

    assert_equal room.user_b, room.other_participant(room.user_a)
    assert_equal room.user_a, room.other_participant(room.user_b)
    assert_nil chat_rooms(:genel).other_participant(users(:one))
  end

  # --- Faz 32c: origin (match vs direct) ---

  test "find_or_create_dm_between varsayilan origin 'direct'tir" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    assert_equal "direct", room.origin
    assert_not room.match_origin?
  end

  test "find_or_create_dm_between origin: 'match' verildiginde odayi match olarak isaretler" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two), origin: "match")
    assert_equal "match", room.origin
    assert room.match_origin?
  end

  test "origin zaten var olan odada find_or_create_by! ile UZERINE YAZILMAZ (blok yalniz create'te calisir)" do
    # Once "match" olarak kur.
    first = ChatRoom.find_or_create_dm_between(users(:one), users(:two), origin: "match")
    assert_equal "match", first.origin

    # Ayni ikili icin "direct" ile tekrar bak — YENI oda uretilmemeli VE origin
    # "match"ten "direct"e DUSMEMELI (bu tam olarak bu kod tabanini daha once
    # isiran find_or_create_by! blok-yalniz-create gotcha'sidir).
    assert_no_difference "ChatRoom.count" do
      second = ChatRoom.find_or_create_dm_between(users(:two), users(:one), origin: "direct")
      assert_equal first.id, second.id
      assert_equal "match", second.origin, "var olan match odasi direct'e dusmemeli"
    end

    assert_equal "match", first.reload.origin
  end

  # --- Canli eslesme guncellemesi: yeni match-origin DM olusunca yayin ---

  test "yeni match-origin DM olusunca her iki katilimcinin matches stream'ine yayin yapar" do
    a = users(:one)
    b = users(:two)

    assert_broadcasts("user_#{a.id}_matches", 1) do
      assert_broadcasts("user_#{b.id}_matches", 1) do
        ChatRoom.find_or_create_dm_between(a, b, origin: "match")
      end
    end
  end

  test "idempotent re-fetch (oda zaten var) yeni yayin yapmaz" do
    a = users(:one)
    b = users(:two)
    ChatRoom.find_or_create_dm_between(a, b, origin: "match") # ilk olusturma yayini

    assert_no_broadcasts("user_#{a.id}_matches") do
      ChatRoom.find_or_create_dm_between(a, b, origin: "match")
    end
  end

  test "direct origin ile olusan DM matches yayini yapmaz" do
    a = users(:one)
    b = users(:two)

    assert_no_broadcasts("user_#{a.id}_matches") do
      ChatRoom.find_or_create_dm_between(a, b, origin: "direct")
    end
  end

  test "match_origin? yalnizca private + origin 'match' oldugunda true" do
    public_room = chat_rooms(:genel)
    public_room.update!(origin: "match") # public olsa bile match_origin? false olmali
    assert_not public_room.match_origin?
  end

  # --- Faz 32d: okunmamis sayaci (sekme "+N" rozeti) ---

  test "unread_count_for kullanicinin okumadigi, baskasinin gonderdigi mesajlari sayar" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    a = room.user_a
    b = room.user_b

    Message.create!(chat_room: room, user: b, body: "okunmamis 1")
    Message.create!(chat_room: room, user: b, body: "okunmamis 2")
    # a'nin kendi gonderdigi mesaj sayilmaz.
    Message.create!(chat_room: room, user: a, body: "kendi mesajim")
    # read_at dolu olan sayilmaz.
    Message.create!(chat_room: room, user: b, body: "okundu", read_at: Time.current)

    assert_equal 2, room.unread_count_for(a)
  end

  test "unread_count_for nil kullanici icin 0 doner" do
    assert_equal 0, chat_rooms(:genel).unread_count_for(nil)
  end

  # --- Blok: yeni DM engellemesi ---

  test "blok varken ve onceden DM yokken yeni DM olusturulmaz (nil doner)" do
    a = users(:one)
    b = users(:two)
    Block.create!(blocker: a, blocked: b)

    assert_no_difference "ChatRoom.count" do
      result = ChatRoom.find_or_create_dm_between(a, b)
      assert_nil result
    end
  end

  test "blok iki yonlu engeller (engellenen taraf da yeni DM acamaz)" do
    a = users(:one)
    b = users(:two)
    Block.create!(blocker: a, blocked: b)

    assert_no_difference "ChatRoom.count" do
      assert_nil ChatRoom.find_or_create_dm_between(b, a)
    end
  end

  test "blok oncesi var olan DM korunur ve dondurulur" do
    a = users(:one)
    b = users(:two)
    existing = ChatRoom.find_or_create_dm_between(a, b)
    Block.create!(blocker: a, blocked: b)

    assert_no_difference "ChatRoom.count" do
      result = ChatRoom.find_or_create_dm_between(a, b)
      assert_equal existing.id, result.id
    end
  end

  test "rated_by? kullanici degerlendirdiyse true doner" do
    room = ChatRoom.find_or_create_dm_between(users(:one), users(:two))
    room.update!(ended_by_a: true, ended_by_b: true)

    assert_not room.rated_by?(room.user_a)

    Rating.create!(rater: room.user_a, rated_user: room.user_b, chat_room: room, score: 5)
    assert room.reload.rated_by?(room.user_a)
    assert_not room.rated_by?(room.user_b)
  end
end
