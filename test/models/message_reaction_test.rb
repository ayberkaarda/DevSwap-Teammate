require "test_helper"

class MessageReactionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "MR-U", provider: "github", uid: "mr-u", terms_accepted_at: Time.current)
    @message = Message.create!(user: @user, chat_room: chat_rooms(:genel), body: "tepki gelsin")
  end

  test "izin listesi disindaki emoji reddedilir" do
    r = MessageReaction.new(user: @user, message: @message, emoji: "not-an-emoji")
    assert_not r.valid?
    assert_includes r.errors[:emoji], "is not included in the list"
  end

  test "izin listesindeki emoji kabul edilir" do
    r = MessageReaction.new(user: @user, message: @message, emoji: MessageReaction::ALLOWED_EMOJI.first)
    assert r.valid?
  end

  test "ayni kullanici ayni mesaja ayni emoji'yi iki kez birakamaz (uniqueness)" do
    emoji = MessageReaction::ALLOWED_EMOJI.first
    MessageReaction.create!(user: @user, message: @message, emoji: emoji)
    dup = MessageReaction.new(user: @user, message: @message, emoji: emoji)

    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "ayni kullanici ayni mesaja FARKLI emoji'lerle tepki verebilir" do
    e1, e2 = MessageReaction::ALLOWED_EMOJI.first(2)
    MessageReaction.create!(user: @user, message: @message, emoji: e1)
    second = MessageReaction.new(user: @user, message: @message, emoji: e2)

    assert second.valid?, "farkli emoji ile ikinci tepki gecerli olmali"
  end

  test "toggle ayni emoji'yi acar ve kapatir" do
    emoji = MessageReaction::ALLOWED_EMOJI.first
    assert_difference "MessageReaction.count", 1 do
      assert_equal true, MessageReaction.toggle(user: @user, message: @message, emoji: emoji)
    end
    assert_difference "MessageReaction.count", -1 do
      assert_equal false, MessageReaction.toggle(user: @user, message: @message, emoji: emoji)
    end
  end

  test "counts_for emoji dagilimini dondurur" do
    other = User.create!(name: "MR-U2", provider: "github", uid: "mr-u2", terms_accepted_at: Time.current)
    e1 = MessageReaction::ALLOWED_EMOJI[0]
    e2 = MessageReaction::ALLOWED_EMOJI[1]
    MessageReaction.create!(user: @user, message: @message, emoji: e1)
    MessageReaction.create!(user: other, message: @message, emoji: e1)
    MessageReaction.create!(user: @user, message: @message, emoji: e2)

    counts = MessageReaction.counts_for(@message)
    assert_equal 2, counts[e1]
    assert_equal 1, counts[e2]
  end

  test "mesaj silinince tepkileri de silinir (dependent: :destroy)" do
    MessageReaction.create!(user: @user, message: @message, emoji: MessageReaction::ALLOWED_EMOJI.first)

    assert_difference "MessageReaction.count", -1 do
      @message.destroy
    end
  end
end
