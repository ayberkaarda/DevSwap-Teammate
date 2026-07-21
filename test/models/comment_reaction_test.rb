require "test_helper"

class CommentReactionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "CR-U", provider: "github", uid: "cr-u", terms_accepted_at: Time.current)
    @post = Post.create!(content: "icerik", user: @user)
    @comment = Comment.create!(content: "yorum", user: @user, post: @post)
  end

  test "izin listesi disindaki emoji reddedilir" do
    r = CommentReaction.new(user: @user, comment: @comment, emoji: "not-an-emoji")
    assert_not r.valid?
    assert_includes r.errors[:emoji], "is not included in the list"
  end

  test "izin listesindeki emoji kabul edilir" do
    r = CommentReaction.new(user: @user, comment: @comment, emoji: CommentReaction::ALLOWED_EMOJI.first)
    assert r.valid?
  end

  test "ayni kullanici ayni yoruma ayni emoji'yi iki kez birakamaz" do
    emoji = CommentReaction::ALLOWED_EMOJI.first
    CommentReaction.create!(user: @user, comment: @comment, emoji: emoji)
    dup = CommentReaction.new(user: @user, comment: @comment, emoji: emoji)

    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "ayni kullanici ayni yoruma FARKLI emoji'lerle tepki verebilir" do
    e1, e2 = CommentReaction::ALLOWED_EMOJI.first(2)
    CommentReaction.create!(user: @user, comment: @comment, emoji: e1)
    second = CommentReaction.new(user: @user, comment: @comment, emoji: e2)

    assert second.valid?, "farkli emoji ile ikinci tepki gecerli olmali"
  end

  test "toggle ayni emoji'yi acar ve kapatir" do
    emoji = CommentReaction::ALLOWED_EMOJI.first
    assert_difference "CommentReaction.count", 1 do
      assert_equal true, CommentReaction.toggle(user: @user, comment: @comment, emoji: emoji)
    end
    assert_difference "CommentReaction.count", -1 do
      assert_equal false, CommentReaction.toggle(user: @user, comment: @comment, emoji: emoji)
    end
  end
end
