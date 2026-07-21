require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
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

  def user!(uid, role: "member")
    User.create!(name: "CC-#{uid}", provider: "github", uid: uid, role: role, terms_accepted_at: Time.current)
  end

  test "yorum olusturma giris gerektirir" do
    u = user!("cc-anon")
    p = Post.create!(content: "x", user: u)
    assert_no_difference "Comment.count" do
      post comments_path, params: { post_id: p.id, content: "yorum" }
    end
    assert_redirected_to root_path
  end

  test "yorum olusturulur" do
    u = user!("cc-1")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    assert_difference "Comment.count", 1 do
      post comments_path, params: { post_id: p.id, content: "harika post" }
    end
    assert_nil Comment.last.parent_id
  end

  test "parent_id ile yanit olusturulur" do
    u = user!("cc-2")
    p = Post.create!(content: "x", user: u)
    root = Comment.create!(content: "kok", user: u, post: p)
    sign_in_via_github(u)

    assert_difference "Comment.count", 1 do
      post comments_path, params: { post_id: p.id, content: "yanit", parent_id: root.id }
    end
    assert_equal root.id, Comment.last.parent_id
  end

  test "susturulmus kullanici yorum yapamaz" do
    u = user!("cc-muted")
    admin = user!("cc-admin", role: "admin")
    p = Post.create!(content: "x", user: u)
    Mute.create!(user: u, muted_by: admin, muted_until: 1.hour.from_now, reason: "test")
    sign_in_via_github(u)

    assert_no_difference "Comment.count" do
      post comments_path, params: { post_id: p.id, content: "yorum" }
    end
  end

  test "kullanici kendi yorumunu silebilir ve silme loglanir" do
    u = user!("cc-3")
    p = Post.create!(content: "x", user: u)
    c = Comment.create!(content: "silinecek", user: u, post: p)
    sign_in_via_github(u)

    assert_difference "Comment.count", -1 do
      assert_difference "ActivityLog.count", 1 do
        delete comment_path(c)
      end
    end
    assert_equal "comment_deleted", ActivityLog.recent.first.action_type
  end

  test "baskasinin yorumu silinemez (yetkisiz)" do
    owner = user!("cc-4")
    other = user!("cc-5")
    p = Post.create!(content: "x", user: owner)
    c = Comment.create!(content: "korunan", user: owner, post: p)
    sign_in_via_github(other)

    assert_no_difference "Comment.count" do
      delete comment_path(c)
    end
  end

  test "staff baskasinin yorumunu silebilir" do
    owner = user!("cc-6")
    admin = user!("cc-7", role: "admin")
    p = Post.create!(content: "x", user: owner)
    c = Comment.create!(content: "silinecek", user: owner, post: p)
    sign_in_via_github(admin)

    assert_difference "Comment.count", -1 do
      delete comment_path(c)
    end
  end
end
