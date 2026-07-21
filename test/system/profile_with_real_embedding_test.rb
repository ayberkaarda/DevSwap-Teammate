require "application_system_test_case"

# Bu test, Faz 11 regresyon testinin ("viewer'in embedding vektoru yokken
# baskasinin profili 500 vermez", bkz. test/controllers/profiles_controller_test.rb)
# TAMAMLAYICISI: viewer'in GERCEK bir embedding vektoru VARKEN /u/:id sayfasinin
# 500 vermedigini ve profil ızgarasının sorunsuz render edildigini gercek bir
# tarayicida (headless Chrome/Edge, Capybara + Selenium) kanitlar.
#
# NOT: "match_analysis" widget'ı profilden kaldirildigi icin eski
# "EŞLEŞME_ANALİZİ render edilir" beklentisi cikarildi; artik eslesme skoru
# hicbir ziyaretciye gosterilmez. Test hala embedding'li viewer'in sayfayi
# patlatmadan gorebildigini dogrular.
#
# NOT: Onceki hatali versiyon development veritabanindaki gercek uid:
# "211174001" kullanicisina referans veriyordu; ama sistem testleri
# RAILS_ENV=test ile TAMAMEN AYRI bir veritabanina (dev_swap_test) karsi
# calisir, o kullanici orada yok. Bu versiyon test/system/omni_command_verification_test.rb
# ile ayni deseni takip ederek gereken tum veriyi (kullanicilar, skill'ler,
# embedding'ler) kendi setup'inda test DB'sinde olusturur.
class ProfileWithRealEmbeddingTest < ApplicationSystemTestCase
  MOCK_UID = "profile-embed-test-viewer"

  def setup
    OmniAuth.config.test_mode = true

    @viewer = User.create!(name: "Embedding Viewer", provider: "github", uid: "profile-embed-test-1", terms_accepted_at: Time.current)
    @target = User.create!(name: "Embedding Hedef", provider: "github", uid: "profile-embed-test-2", terms_accepted_at: Time.current)

    skill_one = Skill.find_or_create_by!(name: "Embedding Test Skill Bir") { |s| s.category = "language" }
    skill_two = Skill.find_or_create_by!(name: "Embedding Test Skill Iki") { |s| s.category = "language" }

    UserSkill.create!(user: @viewer, skill: skill_one, direction: "teaching", source: "manual", weight: 1.0)
    UserSkill.create!(user: @viewer, skill: skill_two, direction: "teaching", source: "manual", weight: 1.0)
    UserSkill.create!(user: @target, skill: skill_one, direction: "learning", source: "manual", weight: 1.0)
    UserSkill.create!(user: @target, skill: skill_two, direction: "learning", source: "manual", weight: 1.0)

    [ @viewer, @target ].each { |u| GenerateUserEmbeddingJob.new.perform(u.id, force: true) }

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

    @viewer&.reload&.user_skills&.destroy_all
    @target&.reload&.user_skills&.destroy_all
    @viewer&.destroy
    @target&.destroy
  end

  test "gercek embedding'e sahip viewer baskasinin profilini 500 olmadan goruntuler" do
    visit "/auth/github/callback"
    visit "/u/#{@target.id}"

    assert_no_text "500"
    assert_no_text "We're sorry, but something went wrong"
    assert_text @target.name
    # Profil ızgarası sorunsuz render edilmeli (match_analysis kaldirildi).
    assert_selector ".grid-stack-item"

    page.save_screenshot(Rails.root.join("tmp/profile_with_real_embedding.png").to_s)
  end
end
