require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
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
    User.create!(name: "L-#{uid}", provider: "github", uid: uid, terms_accepted_at: Time.current)
  end

  test "post begenmek giris gerektirir" do
    u = user!("lc-anon")
    p = Post.create!(content: "x", user: u)

    assert_no_difference "Like.count" do
      post toggle_post_like_path(p)
    end
    assert_redirected_to root_path
  end

  test "post begeni toggle on/off" do
    u = user!("lc-1")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    assert_difference "Like.count", 1 do
      post toggle_post_like_path(p)
    end
    assert_difference "Like.count", -1 do
      post toggle_post_like_path(p)
    end
  end

  test "yorum begeni toggle" do
    u = user!("lc-2")
    p = Post.create!(content: "x", user: u)
    c = Comment.create!(content: "yorum", user: u, post: p)
    sign_in_via_github(u)

    assert_difference "Like.count", 1 do
      post toggle_comment_like_path(c)
    end
    assert_equal "Comment", Like.last.likeable_type
  end

  test "turbo_stream ile begeni etkilesim cubugunu yerinde tazeler ve durumu yansitir" do
    u = user!("lc-ts")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    # Ilk tiklama: begeni ekle. Yanit yalnizca o postun etkilesim cubugunu degistirir.
    post toggle_post_like_path(p), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "post_#{p.id}_interactions", response.body
    # Begenilmis durumda kalp doludur (fill=currentColor) — UI durumu yansitiyor.
    assert_match "currentColor", response.body

    # Ikinci tiklama: begeniyi geri al -> baslangic durumuna dondu (cift kayit YOK).
    assert_difference "Like.count", -1 do
      post toggle_post_like_path(p), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_equal 0, Like.where(likeable: p).count
  end

  test "cift tiklama begeniyi cogaltmaz, baslangic durumuna doner" do
    u = user!("lc-dbl")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    post toggle_post_like_path(p)
    post toggle_post_like_path(p)
    assert_equal 0, Like.where(likeable: p, user: u).count
  end

  test "post_likers begenen kullanicilari listeler" do
    author = user!("lc-3")
    liker = user!("lc-4")
    p = Post.create!(content: "x", user: author)
    Like.create!(user: liker, likeable: p)
    sign_in_via_github(author)

    get post_likers_path(p)
    assert_response :success
    assert_match liker.name, response.body
  end
end
