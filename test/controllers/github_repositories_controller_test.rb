require "test_helper"

class GithubRepositoriesControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "sahibi repo gorunurlugunu degistirebilir" do
    owner = User.create!(name: "Sahip", provider: "github", uid: "grc-1", terms_accepted_at: Time.current)
    repo = GithubRepository.create!(user: owner, name: "repo", full_name: "owner/repo",
                                    html_url: "https://github.com/owner/repo", visible_on_profile: true)

    sign_in_via_github(owner)

    patch github_repository_path(repo), params: { visible_on_profile: false }, as: :json

    assert_response :no_content
    assert_not repo.reload.visible_on_profile
  end

  test "sahibi olmayan baskasinin reposunu degistiremez ve not_found alir" do
    owner = User.create!(name: "Sahip 2", provider: "github", uid: "grc-2", terms_accepted_at: Time.current)
    intruder = User.create!(name: "Yabanci", provider: "github", uid: "grc-3", terms_accepted_at: Time.current)
    repo = GithubRepository.create!(user: owner, name: "repo2", full_name: "owner/repo2",
                                    html_url: "https://github.com/owner/repo2", visible_on_profile: true)

    sign_in_via_github(intruder)

    patch github_repository_path(repo), params: { visible_on_profile: false }, as: :json

    assert_response :not_found
    assert repo.reload.visible_on_profile
  end

  test "giris yapmamis kullanici root_path'e yonlendirilir" do
    owner = User.create!(name: "Sahip 3", provider: "github", uid: "grc-4", terms_accepted_at: Time.current)
    repo = GithubRepository.create!(user: owner, name: "repo3", full_name: "owner/repo3",
                                    html_url: "https://github.com/owner/repo3", visible_on_profile: true)

    patch github_repository_path(repo), params: { visible_on_profile: false }, as: :json

    assert_redirected_to root_path
    assert repo.reload.visible_on_profile
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
