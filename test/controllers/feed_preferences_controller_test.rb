require "test_helper"

class FeedPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "create yeni tercih kaydeder" do
    viewer = User.create!(name: "Prefer", provider: "github", uid: "fp-1", terms_accepted_at: Time.current)
    author = User.create!(name: "Author", provider: "github", uid: "fp-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference "FeedPreference.count", 1 do
      post feed_preferences_path, params: { target_user_id: author.id, preference: "not_interested" }
    end
    pref = FeedPreference.last
    assert_equal "not_interested", pref.preference
  end

  test "ayni yazar icin create tekrar cagirinca tercihi gunceller (upsert), yeni satir olusturmaz" do
    viewer = User.create!(name: "Prefer2", provider: "github", uid: "fp-3", terms_accepted_at: Time.current)
    author = User.create!(name: "Author2", provider: "github", uid: "fp-4", terms_accepted_at: Time.current)
    viewer.feed_preferences.create!(target_user: author, preference: "interested")
    sign_in_via_github(viewer)

    assert_no_difference "FeedPreference.count" do
      post feed_preferences_path, params: { target_user_id: author.id, preference: "not_interested" }
    end
    assert_equal "not_interested", viewer.feed_preferences.find_by(target_user: author).preference
  end

  test "gecersiz preference reddedilir" do
    viewer = User.create!(name: "Prefer3", provider: "github", uid: "fp-5", terms_accepted_at: Time.current)
    author = User.create!(name: "Author3", provider: "github", uid: "fp-6", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_no_difference "FeedPreference.count" do
      post feed_preferences_path, params: { target_user_id: author.id, preference: "belki" }
    end
  end

  test "destroy tercihi kaldirir" do
    viewer = User.create!(name: "Prefer4", provider: "github", uid: "fp-7", terms_accepted_at: Time.current)
    author = User.create!(name: "Author4", provider: "github", uid: "fp-8", terms_accepted_at: Time.current)
    viewer.feed_preferences.create!(target_user: author, preference: "not_interested")
    sign_in_via_github(viewer)

    assert_difference "FeedPreference.count", -1 do
      delete feed_preference_path(author.id)
    end
  end

  test "interested yazarin postu not_interested yazarin postundan once siralanir" do
    viewer = User.create!(name: "FeedViewer", provider: "github", uid: "fp-9", terms_accepted_at: Time.current)
    liked_author = User.create!(name: "LikedAuthor", provider: "github", uid: "fp-10", terms_accepted_at: Time.current)
    disliked_author = User.create!(name: "DislikedAuthor", provider: "github", uid: "fp-11", terms_accepted_at: Time.current)

    # disliked yazarin postu DAHA YENI (normalde once gelirdi); tercih onu geriye iter.
    Post.create!(content: "PREF-DISLIKED-POST", user: disliked_author, created_at: 1.minute.ago)
    Post.create!(content: "PREF-INTERESTED-POST", user: liked_author, created_at: 10.minutes.ago)

    viewer.feed_preferences.create!(target_user: liked_author, preference: "interested")
    viewer.feed_preferences.create!(target_user: disliked_author, preference: "not_interested")
    sign_in_via_github(viewer)

    get posts_path
    assert_response :success
    assert response.body.index("PREF-INTERESTED-POST") < response.body.index("PREF-DISLIKED-POST"),
           "interested yazarin postu not_interested yazarin postundan once gelmeli"
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end
end
