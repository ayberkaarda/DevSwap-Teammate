require "test_helper"

class DismissedConversationTest < ActiveSupport::TestCase
  def setup
    @a = User.create!(name: "Dismiss A", provider: "github", uid: "dc-a", terms_accepted_at: Time.current)
    @b = User.create!(name: "Dismiss B", provider: "github", uid: "dc-b", terms_accepted_at: Time.current)
    @room = ChatRoom.find_or_create_dm_between(@a, @b)
  end

  test "dismiss! bir kayit olusturur ve dismissed_at doldurur" do
    assert_difference "DismissedConversation.count", 1 do
      DismissedConversation.dismiss!(@a, @room)
    end

    dc = DismissedConversation.find_by(user: @a, chat_room: @room)
    assert_not_nil dc.dismissed_at
  end

  test "dismiss! ikinci cagri yeni kayit uretmez, dismissed_at gunceller (upsert)" do
    first = DismissedConversation.dismiss!(@a, @room)
    original_time = first.dismissed_at

    travel 1.minute do
      assert_no_difference "DismissedConversation.count" do
        second = DismissedConversation.dismiss!(@a, @room)
        assert_equal first.id, second.id
        assert second.dismissed_at > original_time
      end
    end
  end

  test "hidden_room_ids_for yeni mesaj YOKKEN kapatilan odayi gizli sayar" do
    DismissedConversation.dismiss!(@a, @room)

    assert_includes DismissedConversation.hidden_room_ids_for(@a), @room.id
  end

  test "hidden_room_ids_for kapatmadan SONRA yeni mesaj gelince odayi gizlemez (geri belirir)" do
    DismissedConversation.dismiss!(@a, @room)

    travel 1.minute do
      Message.create!(chat_room: @room, user: @b, body: "kapatildiktan sonra gelen yeni mesaj")
    end

    assert_not_includes DismissedConversation.hidden_room_ids_for(@a), @room.id
  end

  test "hidden_room_ids_for kapatmadan ONCEKI mesajlari yeni mesaj SAYMAZ (gizli kalir)" do
    Message.create!(chat_room: @room, user: @b, body: "kapatmadan onceki eski mesaj")

    travel 1.minute do
      DismissedConversation.dismiss!(@a, @room)
    end

    assert_includes DismissedConversation.hidden_room_ids_for(@a), @room.id
  end

  test "kapatma per-user'dir: A'nin kapatmasi B'yi etkilemez" do
    DismissedConversation.dismiss!(@a, @room)

    assert_includes DismissedConversation.hidden_room_ids_for(@a), @room.id
    assert_not_includes DismissedConversation.hidden_room_ids_for(@b), @room.id
  end

  test "ayni user+room icin ikinci kayit gecersizdir (uniqueness)" do
    DismissedConversation.create!(user: @a, chat_room: @room, dismissed_at: Time.current)
    dup = DismissedConversation.new(user: @a, chat_room: @room, dismissed_at: Time.current)

    assert_not dup.valid?
  end
end
