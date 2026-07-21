require "test_helper"

class TermsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "kurallari kabul etmemis kullanici herhangi bir sayfaya gitmeye calisinca terms'e yonlendirilir" do
    user = User.create!(name: "Kural Onaylamamis", provider: "github", uid: "terms-1")
    sign_in_via_github(user)

    get root_path

    assert_redirected_to terms_path
  end

  test "terms sayfasinin kendisi yonlendirme dongusune girmez" do
    user = User.create!(name: "Kural Onaylamamis 2", provider: "github", uid: "terms-2")
    sign_in_via_github(user)

    get terms_path

    assert_response :success
  end

  test "giris yapmamis ziyaretci terms sayfasindan reddedilir" do
    get terms_path

    assert_redirected_to root_path
  end

  test "accept sonrasi kullanici artik yonlendirilmez" do
    user = User.create!(name: "Kabul Eden", provider: "github", uid: "terms-3")
    sign_in_via_github(user)

    post accept_terms_path

    assert_redirected_to root_path
    assert user.reload.terms_accepted?

    get root_path

    assert_response :success
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
