require "test_helper"

class LikeTest < ActiveSupport::TestCase
  def user!(uid)
    User.create!(name: "U-#{uid}", provider: "github", uid: uid, terms_accepted_at: Time.current)
  end

  def post!(author)
    Post.create!(content: "icerik", user: author)
  end

  test "ayni kullanici ayni postu iki kez begenemez (uniqueness)" do
    u = user!("like-1")
    p = post!(u)
    Like.create!(user: u, likeable: p)
    dup = Like.new(user: u, likeable: p)

    assert_not dup.valid?
    assert_includes dup.errors[:user_id], "has already been taken"
  end

  test "ayni kullanici hem bir postu hem bir yorumu begenebilir (polymorphic)" do
    u = user!("like-2")
    p = post!(u)
    c = Comment.create!(content: "yorum", user: u, post: p)

    Like.create!(user: u, likeable: p)
    like_on_comment = Like.new(user: u, likeable: c)

    assert like_on_comment.valid?, "farkli likeable_type icin ayri begeni gecerli olmali"
  end

  test "toggle acar ve kapatir" do
    u = user!("like-3")
    p = post!(u)

    assert_difference "Like.count", 1 do
      assert_equal true, Like.toggle(user: u, likeable: p)
    end
    assert_difference "Like.count", -1 do
      assert_equal false, Like.toggle(user: u, likeable: p)
    end
  end
end
