require "application_system_test_case"

# Faz 21 / Bug 2 REGRESYON: Dashboard'daki eslesme/kesif kartlarindaki kullanici
# adi linkleri "nodes_grid" turbo_frame'inin ICINDE yer aliyordu. Link'e
# tiklaninca Turbo, hedef profil sayfasinda "nodes_grid" adli bir frame ariyor,
# bulamayinca "Content missing" hatasi veriyordu. Fix: bu linklere
# data-turbo-frame="_top" eklendi; artik TUM sayfa normal sekilde degisiyor.
#
# Bu test, dashboard'dan bir kullanici kartina tiklaninca gercekten profil
# sayfasina gidildigini (hata/"Content missing"/500 DEGIL) gercek bir tarayicida
# (headless Chrome/Edge, Capybara + Selenium) uctan uca kanitlar. Desen
# test/system/omni_command_verification_test.rb ile ayni.
class DashboardProfileNavigationTest < ApplicationSystemTestCase
  MOCK_UID = "dash-nav-viewer"

  def setup
    OmniAuth.config.test_mode = true

    # Viewer'in embedding vektoru yok -> MatchFinder fallback ile TUM kullanicilari
    # duz kart olarak listeler; boylece hedef kart garanti dashboard'da gorunur.
    @viewer = User.create!(name: "Nav Viewer", provider: "github", uid: "dash-nav-1", terms_accepted_at: Time.current)
    @target = User.create!(name: "Hedef Profil Node", provider: "github", uid: "dash-nav-2", terms_accepted_at: Time.current, bio: "Hedef biyografi")

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: MOCK_UID,
      info: { name: @viewer.name, email: @viewer.email, nickname: MOCK_UID, image: @viewer.avatar_url },
      credentials: { token: "test-token" }
    )
    @viewer.update!(provider: "github", uid: MOCK_UID)
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil

    @viewer&.destroy
    @target&.destroy
  end

  test "dashboard'daki kullanici kartina tiklaninca Content missing olmadan profil sayfasina gidilir" do
    visit "/auth/github/callback"
    visit root_path

    assert_text @target.name

    click_on @target.name

    assert_current_path public_profile_path(@target.id)
    assert_no_text "Content missing"
    assert_no_text "500"
    assert_no_text "We're sorry, but something went wrong"
    assert_text @target.name

    page.save_screenshot(Rails.root.join("tmp/dashboard_profile_navigation.png").to_s)
  end
end
