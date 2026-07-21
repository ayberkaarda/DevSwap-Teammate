require "application_system_test_case"

# Faz 31e — Minimal DM Modu.
# chatbox DashboardWidget'ı gizlendiğinde alt kısımda beliren alternatif DM
# dock'unun uçtan uca çalıştığını gerçek bir tarayıcıda (headless Chrome/Edge,
# Capybara + Selenium) doğrular:
#   1. Dock, karşı katılımcının adı + okunmamış rozeti ile render edilir.
#   2. Bir DM kutusuna tıklanınca yukarı açılan popup, chat_panel Turbo Frame'inin
#      src'ini rooms#show'a yönlendirir (frame promotion) ve GERÇEK sohbet
#      içeriğini (önceden gönderilmiş mesajın gövdesi + #terminal-form) yükler.
#
# NOT: Sistem testleri ayrı bir tarayıcı prosesi kullandığı için
# use_transactional_tests = false'dur; oluşturulan tüm veriyi teardown'da
# (izole test DB'sinde) elle temizliyoruz — dashboard_grid_test.rb ve
# profile_with_real_embedding_test.rb ile paylaşılan artık satır bırakmadan.
class MinimalDmModeTest < ApplicationSystemTestCase
  MOCK_UID = "minimal-dm-test-viewer"

  def setup
    OmniAuth.config.test_mode = true

    @viewer = User.create!(name: "Minimal DM Viewer", provider: "github", uid: "minimal-dm-test-1", terms_accepted_at: Time.current)
    @other  = User.create!(name: "Minimal DM Partner", provider: "github", uid: "minimal-dm-test-2", terms_accepted_at: Time.current)

    # DashboardController genel (private olmayan) bir ChatRoom bekler.
    unless ChatRoom.public_rooms.exists?
      ChatRoom.find_or_create_by!(slug: "minimal-dm-test-public-room") do |room|
        room.name = "Genel"
        room.private = false
        room.position = 1
      end
    end

    # İki kullanıcı arasında en az bir OKUNMAMIŞ mesaj içeren DM odası.
    @dm_room = ChatRoom.find_or_create_dm_between(@viewer, @other)
    @unread_message = Message.create!(chat_room: @dm_room, user: @other, body: "Merhaba, bu okunmamis bir DM mesaji.")

    # Widget'ları elle tohumla ve chatbox'ı gizle (Minimal DM Modu koşulu).
    DashboardWidget.seed_defaults_for(@viewer) if @viewer.dashboard_widgets.none?
    @viewer.dashboard_widgets.find_by(widget_type: "chatbox").update!(visible: false)

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: MOCK_UID,
      info: { name: @viewer.name, email: @viewer.email, nickname: MOCK_UID, image: nil },
      credentials: { token: "test-token" }
    )
    @viewer.update!(provider: "github", uid: MOCK_UID)
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil

    @dm_room&.messages&.destroy_all
    @viewer&.reload&.dashboard_widgets&.destroy_all
    @dm_room&.destroy
    @viewer&.destroy
    @other&.destroy
  end

  test "chatbox gizliyken minimal DM dock'u gorunur, tiklaninca gercek sohbet icerigi yuklenir" do
    visit "/auth/github/callback"
    visit "/"

    # 1. Dock, karşı katılımcının adı ile render edilmiş olmalı (<=3 DM: isim modu).
    assert_selector "[data-controller='minimal-dm']"
    assert_text @other.name

    # Okunmamış rozeti (1 adet okunmamış mesaj) görünmeli.
    within "[data-controller='minimal-dm']" do
      assert_text "1"
    end

    # 2. DM kutusuna tıkla → popup yukarı açılır, Turbo Frame src swap ile GERÇEK
    #    sohbet içeriğini yükler (boş frame değil).
    find("button[data-room-slug='#{@dm_room.slug}']").click

    # Capybara varsayılan bekleme davranışı async frame yüklemesini bekler.
    assert_selector "#terminal-form"
    assert_selector "#chat-messages"
    assert_text @unread_message.body

    page.save_screenshot(Rails.root.join("tmp/minimal_dm_mode.png").to_s)
  end
end
