require "test_helper"

class RatingsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )
    get "/auth/github/callback"
  end

  def ended_room(user_a, user_b)
    room = ChatRoom.find_or_create_dm_between(user_a, user_b)
    room.update!(ended_by_a: true, ended_by_b: true)
    room
  end

  test "oda sonlanmadan degerlendirme yapilamaz (forbidden)" do
    a = User.create!(name: "RA1", provider: "github", uid: "rc-a1", terms_accepted_at: Time.current)
    b = User.create!(name: "RB1", provider: "github", uid: "rc-b1", terms_accepted_at: Time.current)
    room = ChatRoom.find_or_create_dm_between(a, b)
    sign_in_via_github(a)

    assert_no_difference "Rating.count" do
      post ratings_path, params: { room_slug: room.slug, score: 5, note: "erken" }
    end
    assert_response :forbidden
  end

  test "katilimci olmayan degerlendiremez (forbidden)" do
    a = User.create!(name: "RA2", provider: "github", uid: "rc-a2", terms_accepted_at: Time.current)
    b = User.create!(name: "RB2", provider: "github", uid: "rc-b2", terms_accepted_at: Time.current)
    room = ended_room(a, b)

    outsider = User.create!(name: "ROUT", provider: "github", uid: "rc-out", terms_accepted_at: Time.current)
    sign_in_via_github(outsider)

    assert_no_difference "Rating.count" do
      post ratings_path, params: { room_slug: room.slug, score: 5, note: "yabanci" }
    end
    assert_response :forbidden
  end

  test "ayni kisi iki kez degerlendiremez" do
    a = User.create!(name: "RA3", provider: "github", uid: "rc-a3", terms_accepted_at: Time.current)
    b = User.create!(name: "RB3", provider: "github", uid: "rc-b3", terms_accepted_at: Time.current)
    room = ended_room(a, b)
    sign_in_via_github(a)

    post ratings_path, params: { room_slug: room.slug, score: 5, note: "ilk" }
    assert_equal 1, Rating.count

    assert_no_difference "Rating.count" do
      post ratings_path, params: { room_slug: room.slug, score: 1, note: "ikinci" }
    end
    assert_redirected_to room_path(room.slug)
    assert_equal "Zaten değerlendirdin.", flash[:alert]
  end

  test "basarili degerlendirme sonrasi average_rating guncellenir" do
    a = User.create!(name: "RA4", provider: "github", uid: "rc-a4", terms_accepted_at: Time.current)
    b = User.create!(name: "RB4", provider: "github", uid: "rc-b4", terms_accepted_at: Time.current)
    room = ended_room(a, b)
    sign_in_via_github(a)

    assert_difference "Rating.count", 1 do
      post ratings_path, params: { room_slug: room.slug, score: 4, note: "iyi" }
    end
    assert_redirected_to room_path(room.slug)

    b.reload
    assert_in_delta 4.0, b.average_rating, 0.001
    assert_equal 1, b.ratings_count
  end
end
