require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "belongs to a post and a user" do
    comment = comments(:one)
    assert_equal posts(:one), comment.post
    assert_equal users(:one), comment.user
  end

  def setup
    @user = User.create!(name: "C-U", provider: "github", uid: "c-u", terms_accepted_at: Time.current)
    @post = Post.create!(content: "icerik", user: @user)
  end

  test "content bos olamaz" do
    c = Comment.new(user: @user, post: @post, content: "")
    assert_not c.valid?
    assert_includes c.errors[:content], "can't be blank"
  end

  test "top_level scope yalnizca parent'siz yorumlari doner" do
    root = Comment.create!(content: "kok", user: @user, post: @post)
    Comment.create!(content: "yanit", user: @user, post: @post, parent: root)

    assert_equal [ root ], @post.comments.top_level.to_a
  end

  test "parent/replies iliskisi (threaded)" do
    root = Comment.create!(content: "kok", user: @user, post: @post)
    reply1 = Comment.create!(content: "y1", user: @user, post: @post, parent: root)
    reply2 = Comment.create!(content: "y2", user: @user, post: @post, parent: root)

    assert_equal root, reply1.parent
    assert_equal [ reply1, reply2 ].sort_by(&:id), root.replies.order(:id).to_a
  end

  test "kok yorum silinince yanitlari da silinir (dependent destroy)" do
    root = Comment.create!(content: "kok", user: @user, post: @post)
    Comment.create!(content: "yanit", user: @user, post: @post, parent: root)

    assert_difference "Comment.count", -2 do
      root.destroy
    end
  end

  test "yorum silinince begenileri ve tepkileri de silinir" do
    c = Comment.create!(content: "yorum", user: @user, post: @post)
    Like.create!(user: @user, likeable: c)
    CommentReaction.create!(user: @user, comment: c, emoji: CommentReaction::ALLOWED_EMOJI.first)

    assert_difference [ "Like.count", "CommentReaction.count" ], -1 do
      c.destroy
    end
  end
end
