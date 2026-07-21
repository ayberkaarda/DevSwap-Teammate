require "application_system_test_case"

# Bu test, /omni komutunun dashboard sohbet terminalinde çalıştığında
# app/javascript/channels/terminal_chat_channel.js'nin `omni-stats` meta tag'ini
# TAZE okuduğunu (modül-seviyesinde donuk/eski bir değer kullanmadığını) gerçek
# bir tarayıcıda (headless Chrome/Edge, Capybara + Selenium) uçtan uca kanıtlar.
#
# NOT: `bin/rails test` her zaman test ortamını (dev_swap_test veritabanını)
# kullanır ve test_helper.rb'deki `fixtures :all` her test çalışmasında ilgili
# tabloları TEMİZLEYİP fixture verisiyle yeniden doldurur. Bu davranışı gerçek
# development veritabanına (dev_swap_development, db/seeds.rb ile doldurulmuş)
# karşı zorlamak (`RAILS_ENV=development bin/rails test ...`) fixtures'ın o
# veritabanını silip yeniden doldurmasına yol açar — bu, CLAUDE.md'nin
# "Destructive Command Safety" kuralı kapsamına giren, onay alınmadan
# yapılamayacak bir işlemdir. Bu yüzden gerçek dev DB'ye HİÇ dokunulmuyor;
# bunun yerine izole test veritabanında db/seeds.rb'deki "Ayberk" senaryosunu
# birebir yansıtan bir demo kullanıcı (teaching: 2, learning: 1) bu testin
# kendi setup'ında oluşturuluyor. Doğrulanan mekanizma (meta tag + JS okuma
# mantığı) ortamdan bağımsız olduğu için bu, fix'in gerçekliğini aynı güçte kanıtlar.
class OmniCommandVerificationTest < ApplicationSystemTestCase
  DEMO_EMAIL = "omni-verify-demo@devswap.com"
  MOCK_UID = "demo-omni-verify"

  def setup
    @demo_user = User.find_or_create_by!(email: DEMO_EMAIL) do |u|
      u.name = "Ayberk"
      u.terms_accepted_at = Time.current # <-- YENİ KULLANICI İÇİN ONAY
    end
    @original_provider = @demo_user.provider
    @original_uid = @demo_user.uid

    teaching_skill_one = Skill.find_or_create_by!(name: "Java / Spring Boot")
    teaching_skill_two = Skill.find_or_create_by!(name: "Angular")
    learning_skill = Skill.find_or_create_by!(name: "Ruby on Rails")

    @demo_user.user_skills.destroy_all
    UserSkill.create!(user: @demo_user, skill: teaching_skill_one, direction: "teaching", source: "manual", weight: 0.8)
    UserSkill.create!(user: @demo_user, skill: teaching_skill_two, direction: "teaching", source: "manual", weight: 0.6)
    UserSkill.create!(user: @demo_user, skill: learning_skill, direction: "learning", source: "manual", weight: 0.5)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: "github",
      uid: MOCK_UID,
      info: { name: "Ayberk", email: DEMO_EMAIL, image: nil, nickname: "ayberk-demo" },
      credentials: { token: "fake-token" }
    })

    # Var olan kullanıcı bulunursa onun için de onayı güncelliyoruz
    @demo_user.update!(
      provider: "github",
      uid: MOCK_UID,
      terms_accepted_at: Time.current # <-- MEVCUT KULLANICI İÇİN ONAY
    )
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false

    # Sistem testleri ayrı bir tarayıcı prosesi/thread kullandığı için
    # use_transactional_tests = false'dur; transaction rollback'e güvenmeden
    # test veritabanını manuel olarak temizliyoruz (izole test DB, dev DB değil).
    @demo_user&.reload&.update!(provider: @original_provider, uid: @original_uid)
    @demo_user&.user_skills&.destroy_all
    @demo_user&.destroy
  end

  test "/omni komutu dashboard terminalinde doğru teaching/learning skill sayılarını gösterir" do
    visit root_path

    click_on "GitHub ile Giriş Yap"

    assert_current_path root_path
    assert_text "Ayberk"

    within "#terminal-form" do
      input = find('input[type="text"]')
      input.click
      input.send_keys("/omni")
      input.send_keys(:enter)
    end

    assert_text "[SYS_EXEC]"
    assert_text "Teaching: 2 skill"
    assert_text "Learning: 1 skill"

    page.save_screenshot(Rails.root.join("tmp/omni_verification.png").to_s)
  end
end
