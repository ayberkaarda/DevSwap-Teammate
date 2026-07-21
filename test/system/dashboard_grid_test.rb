require "application_system_test_case"

# Bu test, Faz 31 dashboard yeniden tasarımının (Gridstack tabanlı widget grid'i)
# uçtan uca çalıştığını gerçek bir tarayıcıda (headless Chrome/Edge, Capybara +
# Selenium) doğrular: giriş yapan kullanıcı grid konteynerini, migrate edilmiş
# terminal chat widget'ını ve düzenleme moduna geçişi görebilmelidir.
#
# NOT: test/fixtures/chat_rooms.yml, test_helper.rb'deki `fixtures :all`
# sayesinde her test çalışmasında yüklenir; DashboardController bu fixture'lardan
# gelen genel (private olmayan) bir ChatRoom bulur. DashboardWidget'lar ise
# DashboardController#index içinde ilk ziyarette lazy olarak
# (DashboardWidget.seed_defaults_for) oluşturulur, bu yüzden burada manuel
# widget oluşturmaya gerek yoktur.
class DashboardGridTest < ApplicationSystemTestCase
  DEMO_EMAIL = "dashboard-grid-demo@devswap.com"
  MOCK_UID = "demo-dashboard-grid"

  def setup
    @demo_user = User.find_or_create_by!(email: DEMO_EMAIL) do |u|
      u.name = "Ayberk"
      u.terms_accepted_at = Time.current # <-- YENİ KULLANICI İÇİN ONAY
    end
    @original_provider = @demo_user.provider
    @original_uid = @demo_user.uid

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

    # DashboardController genel (private olmayan) bir ChatRoom bekler.
    # Fixtures normalde bunu sağlar; bulunamazsa güvenlik ağı olarak burada
    # oluşturuyoruz (idempotent, slug üzerinden find_or_create_by!).
    @demo_user.dashboard_widgets.destroy_all
    return if ChatRoom.public_rooms.exists?

    ChatRoom.find_or_create_by!(slug: "dashboard-grid-test-room") do |room|
      room.name = "Genel"
      room.private = false
      room.position = 1
    end
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false

    # Sistem testleri ayrı bir tarayıcı prosesi/thread kullandığı için
    # use_transactional_tests = false'dur; transaction rollback'e güvenmeden
    # test veritabanını manuel olarak temizliyoruz (izole test DB, dev DB değil).
    @demo_user&.reload&.update!(provider: @original_provider, uid: @original_uid)
    @demo_user&.dashboard_widgets&.destroy_all
    @demo_user&.destroy
  end

  test "dashboard grid yüklenir, chatbox widget'ı içerir ve düzenleme moduna geçilebilir" do
    visit root_path

    click_on "GitHub ile Giriş Yap"

    assert_current_path root_path
    assert_text "Ayberk"

    # Gridstack konteyneri render edilmiş olmalı
    assert_selector ".grid-stack"

    # Migrate edilmiş chatbox widget'ının içeriği (terminal chat başlığı) görünmeli
    # (başlık `uppercase` Tailwind sınıfı taşıdığından Capybara görünen metni
    # büyük harfle okur; case-insensitive eşleştiriyoruz)
    assert_text(/Global_Terminal\.exe/i)

    # Düzenleme modu kontrolü mevcut olmalı ve tıklandığında etkinleşmeli
    assert_button "Düzenle"
    click_on "Düzenle"

    # Düzenleme modu açıldığında buton metni "Bitir"e döner ve widget başına
    # gizli "Gizle" butonları görünür hale gelir (Capybara varsayılan olarak
    # sadece görünür elementleri eşleştirir).
    assert_text "Bitir"
    assert_selector "button", text: "Gizle", visible: true

    page.save_screenshot(Rails.root.join("tmp/dashboard_grid.png").to_s)
  end
end
