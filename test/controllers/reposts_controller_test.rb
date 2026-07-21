require "test_helper"

class RepostsControllerTest < ActionDispatch::IntegrationTest
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
    User.create!(name: "R-#{uid}", provider: "github", uid: uid, terms_accepted_at: Time.current)
  end

  test "repost toggle on/off" do
    u = user!("rc-1")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    assert_difference "Repost.count", 1 do
      post toggle_repost_path(p)
    end
    assert_difference "Repost.count", -1 do
      post toggle_repost_path(p)
    end
  end

  test "giris gerektirir" do
    u = user!("rc-anon")
    p = Post.create!(content: "x", user: u)
    assert_no_difference "Repost.count" do
      post toggle_repost_path(p)
    end
    assert_redirected_to root_path
  end

  test "turbo_stream ile repost etkilesim cubugunu yerinde tazeler, cift kayit olusturmaz" do
    u = user!("rc-ts")
    p = Post.create!(content: "x", user: u)
    sign_in_via_github(u)

    post toggle_repost_path(p), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "post_#{p.id}_interactions", response.body
    assert_equal 1, Repost.where(post: p, user: u).count

    # Ikinci tiklama toggle off eder; DB'de asla 1'den fazla kayit olmaz.
    post toggle_repost_path(p), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_equal 0, Repost.where(post: p, user: u).count
  end

  test "post_reposters repost edenleri listeler" do
    author = user!("rc-2")
    reposter = user!("rc-3")
    p = Post.create!(content: "x", user: author)
    Repost.create!(user: reposter, post: p)
    sign_in_via_github(author)

    get post_reposters_path(p)
    assert_response :success
    assert_match reposter.name, response.body
  end
end
