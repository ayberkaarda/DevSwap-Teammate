require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "belongs to a user" do
    assert_equal users(:one), messages(:one).user
  end

  test "is invalid without a user" do
    message = Message.new(body: "hello")
    assert_not message.valid?
  end

  # --- Faz 32c: duzenleme + yayin ---

  test "edited? edited_at doluysa true doner" do
    message = Message.create!(user: users(:one), chat_room: chat_rooms(:genel), body: "orijinal")
    assert_not message.edited?

    message.update!(body: "yeni", edited_at: Time.current)
    assert message.reload.edited?
  end

  test "olusturuldugunda ilgili odaya 'message' yayini yapilir" do
    slug = chat_rooms(:genel).slug
    assert_broadcasts("terminal_chat_channel_#{slug}", 1) do
      Message.create!(user: users(:one), chat_room: chat_rooms(:genel), body: "yayin testi")
    end
  end

  test "govde duzenlenince 'message_edited' yayini yapilir" do
    message = Message.create!(user: users(:one), chat_room: chat_rooms(:genel), body: "ilk")
    slug = chat_rooms(:genel).slug

    assert_broadcasts("terminal_chat_channel_#{slug}", 1) do
      message.update!(body: "duzenlendi", edited_at: Time.current)
    end
  end

  test "read_at update_column ile yazilinca duzenleme yayini YAPILMAZ" do
    message = Message.create!(user: users(:one), chat_room: chat_rooms(:genel), body: "okundu-testi")
    slug = chat_rooms(:genel).slug

    assert_no_broadcasts("terminal_chat_channel_#{slug}") do
      message.update_column(:read_at, Time.current)
    end
  end

  test "silinince 'message_deleted' yayini yapilir" do
    message = Message.create!(user: users(:one), chat_room: chat_rooms(:genel), body: "silinecek")
    slug = chat_rooms(:genel).slug

    assert_broadcasts("terminal_chat_channel_#{slug}", 1) do
      message.destroy
    end
  end
end
