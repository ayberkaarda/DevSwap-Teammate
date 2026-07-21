require "test_helper"

class GithubRepositoryTest < ActiveSupport::TestCase
  test "visible scope yalnizca visible_on_profile true olan repolari dondurur" do
    owner = User.create!(name: "Repo Sahibi", provider: "github", uid: "gr-1", terms_accepted_at: Time.current)

    shown = GithubRepository.create!(user: owner, name: "gorunur", full_name: "owner/gorunur",
                                     html_url: "https://github.com/owner/gorunur", visible_on_profile: true)
    hidden = GithubRepository.create!(user: owner, name: "gizli", full_name: "owner/gizli",
                                      html_url: "https://github.com/owner/gizli", visible_on_profile: false)

    result = owner.github_repositories.visible

    assert_includes result, shown
    assert_not_includes result, hidden
  end

  test "visible_on_profile varsayilan olarak true" do
    owner = User.create!(name: "Repo Sahibi 2", provider: "github", uid: "gr-2", terms_accepted_at: Time.current)
    repo = GithubRepository.create!(user: owner, name: "varsayilan", full_name: "owner/varsayilan",
                                    html_url: "https://github.com/owner/varsayilan")

    assert repo.visible_on_profile
  end
end
