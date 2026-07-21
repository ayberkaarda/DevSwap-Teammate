require "test_helper"

class EscalationsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "staff olmayan kullanici eskalasyon gonderemez" do
    member = User.create!(name: "Uye", provider: "github", uid: "ec-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ec-t1", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    assert_no_difference "Escalation.count" do
      post escalations_path, params: { target_user_id: target.id, description: "banlanmali" }
    end
    assert_redirected_to root_path
  end

  test "moderator admin'e eskalasyon gonderebilir" do
    mod = User.create!(name: "Mod", provider: "github", uid: "ec-mod", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ec-t2", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    assert_difference "Escalation.count", 1 do
      post escalations_path, params: { target_user_id: target.id, description: "bu kullanici kural ihlal etti" }
    end
    escalation = Escalation.last
    assert_equal mod, escalation.reported_by
    assert_equal target, escalation.target_user
    assert_equal "pending", escalation.status
  end

  test "admin da eskalasyon gonderebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ec-admin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ec-t3", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "Escalation.count", 1 do
      post escalations_path, params: { target_user_id: target.id, description: "kanit ekli" }
    end
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )

    get "/auth/github/callback"
  end
end
