require "application_system_test_case"

# Bug fix regression test: dashboard edit modunda chatbox widget'ı "Gizle" ile
# gizlendiğinde, minimal DM dock'unun (app/views/dashboard/_minimal_dm_bar.html.erb)
# TAM SAYFA YENİLEMESİ OLMADAN (manuel reload / yeni navigasyon gerekmeden) hemen
# görünür hale gelmesi gerekir. Kök neden: minimal DM dock'unun render koşulu
# sunucu tarafında (index.html.erb) değerlendirilir; dashboard_grid_controller.js
# artık chatbox widget'ı gizlenince/gösterilince Turbo.visit(..., action: "replace")
# ile Turbo destekli bir tam sayfa yenileme tetikliyor (bkz. hideWidget/showWidget/
# refreshIfChatbox). Diğer widget'lar (ör. clock) için HİÇBİR yenileme
# tetiklenmemeli.
#
# NOT: Sistem testleri ayrı bir tarayıcı prosesi kullandığı için
# use_transactional_tests = false'dur; oluşturulan veriyi teardown'da elle
# temizliyoruz (dashboard_grid_test.rb ve minimal_dm_mode_test.rb ile aynı desen).
class DashboardDmDockTest < ApplicationSystemTestCase
  MOCK_UID = "dm-dock-test-viewer"

  def setup
    # Flakiness fix: tam test suite'i altında (izole çalıştırmada değil) bu
    # dosyadaki testler ara sıra `ElementClickInterceptedError` ile
    # patlıyordu. Kök nedeni araştırırken (page.evaluate_script ile gerçek
    # getBoundingClientRect / elementFromPoint ölçümleri alınarak) tespit
    # edildi: test/system/theme_dropdown_test.rb içindeki bir test
    # `page.driver.browser.manage.window.resize_to(390, 800)` çağırıyor ve
    # pencereyi ASLA eski boyutuna geri getirmiyor. Capybara aynı tarayıcı
    # penceresini test sınıfları arasında yeniden kullandığından, bu dar
    # (mobil) viewport dosyamıza SIZIYOR: dar genişlikte GridStack widget'ları
    # farklı/çakışan konumlara yerleşiyor ve sabit konumlu dev-feed-log
    # terminal widget'ı ya da komşu bir grid-stack-item, "Gizle" butonunun
    # üzerine biniyor (bu, doğrudan page.evaluate_script ile ölçülerek
    # doğrulandı — bkz. PR/commit notları). O dosya bu ajanın sahipliğinde
    # değil (yalnızca bu dosya sahipliğimizde); bu yüzden kalıcı çözüm o
    # dosyada pencereyi geri almak olsa da, KENDİ testlerimizi diğer
    # testlerin yan etkilerinden bağımsız/izole kılmak için burada pencereyi
    # bilinen iyi bir boyuta (driven_by'daki screen_size ile eşleşen
    # 1400x1400) açıkça sıfırlıyoruz. Bu kör bir `sleep` değildir; testin
    # çalışma sırasından/önceki testlerden gerçekten bağımsız olmasını
    # sağlayan bir izolasyon düzeltmesidir.
    page.driver.browser.manage.window.resize_to(1400, 1400)

    OmniAuth.config.test_mode = true

    @viewer = User.create!(name: "DM Dock Viewer", provider: "github", uid: "dm-dock-test-1", terms_accepted_at: Time.current)
    @other  = User.create!(name: "DM Dock Partner", provider: "github", uid: "dm-dock-test-2", terms_accepted_at: Time.current)

    unless ChatRoom.public_rooms.exists?
      ChatRoom.find_or_create_by!(slug: "dm-dock-test-public-room") do |room|
        room.name = "Genel"
        room.private = false
        room.position = 1
      end
    end

    # Görünür olması gereken bir DM dock'u için karşı taraf ile bir DM odası.
    @dm_room = ChatRoom.find_or_create_dm_between(@viewer, @other)

    # Widget'ları tohumla; chatbox VE clock başlangıçta görünür olsun.
    DashboardWidget.seed_defaults_for(@viewer) if @viewer.dashboard_widgets.none?
    @viewer.dashboard_widgets.find_by(widget_type: "chatbox").update!(visible: true)
    @viewer.dashboard_widgets.find_by(widget_type: "clock").update!(visible: true)

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

    @viewer&.reload&.dashboard_widgets&.destroy_all
    @dm_room&.destroy
    @viewer&.destroy
    @other&.destroy
  end

  test "chatbox widget'ı Gizle ile gizlenince minimal DM dock'u yenileme olmadan hemen görünür" do
    visit "/auth/github/callback"
    visit "/"

    # Başlangıçta chatbox görünür olduğundan dock henüz render edilmemiş olmalı.
    assert_no_selector "[data-controller='minimal-dm']"

    click_on "Düzenle"
    assert_text "Bitir"

    click_widget_hide_button(widget_type: "chatbox")

    # Turbo.visit(action: "replace") tetiklenip sayfa yeniden render edildikten
    # sonra dock görünmeli. Capybara varsayılan bekleme davranışı bu async
    # navigasyonu bekler; manuel bir `visit` / reload çağrısı YAPMIYORUZ.
    assert_selector "[data-controller='minimal-dm']"
    assert_text @other.name

    page.save_screenshot(Rails.root.join("tmp/dashboard_dm_dock_after_hide.png").to_s)
  end

  test "chatbox olmayan bir widget (clock) Gizle ile gizlenince DM dock'u tetiklenmez" do
    visit "/auth/github/callback"
    visit "/"

    assert_no_selector "[data-controller='minimal-dm']"

    click_on "Düzenle"
    assert_text "Bitir"

    click_widget_hide_button(widget_type: "clock")

    # clock widget'ı grid'den kaldırılmalı (Gridstack DOM manipülasyonu).
    assert_no_selector ".grid-stack-item[data-widget-type='clock']"

    # chatbox hâlâ görünür olduğundan minimal DM dock'u render EDİLMEMELİ
    # (ne önce ne şimdi bir Turbo full-page visit tetiklenmediğinden emin
    # olmanın dolaylı ama güvenilir yolu: dock hiçbir zaman belirmez).
    assert_no_selector "[data-controller='minimal-dm']"

    # Düzenleme modu hâlâ aktif olmalı: bir sayfa navigasyonu olsaydı edit
    # modu sıfırlanır ve "Düzenle" butonu tekrar görünürdü. Bu, clock
    # gizlemenin herhangi bir Turbo tam sayfa ziyaretini TETİKLEMEDİĞİNE
    # dair dolaylı ama makul bir kanıttır.
    assert_text "Bitir"
    assert_no_text "Düzenle", exact: true
  end

  private

  # Edit modundaki bir widget'ın "Gizle" butonuna tıklar.
  #
  # İkincil güvenlik önlemi (asıl kök neden setup'taki pencere boyutu
  # düzeltmesiyle ele alınıyor — yukarıya bakın): GridStack varsayılan olarak
  # `animate: true` ile başlar (bkz. vendor/javascript/gridstack.js
  # `setAnimation` / `v={...,animate:!0,...}`) ve init sırasında grid
  # konteynerine "grid-stack-animate" sınıfını ekler; bu sınıf
  # app/assets/stylesheets/gridstack.css'te left/right/top/width/height için
  # 0.3s'lik CSS transition tanımlar. Widget'lar bu geçiş sırasında kısa süreliğine
  # komşularının üzerinden kayabilir. Kör bir `sleep` eklemek yerine, Web
  # Animations API (`Element#getAnimations`) ile grid içindeki tüm CSS
  # transition'larının fiilen bittiğini aktif olarak polling ile doğruluyoruz
  # — yani gerçek bir sinyali bekliyoruz, sabit bir süreyi değil.
  def click_widget_hide_button(widget_type:)
    wait_for_grid_stack_layout_to_settle

    within ".grid-stack-item[data-widget-type='#{widget_type}']" do
      assert_selector ".widget-edit-chrome", visible: true
      Capybara.using_wait_time(10) { click_on "Gizle" }
    end
  end

  # GridStack'in "grid-stack-animate" CSS transition'ları (left/top/width/
  # height, 0.3s) bitene kadar aktif olarak bekler. `getAnimations()` CSS
  # transition'larını da (Web Animations API üzerinden) raporlar; hiçbir
  # .grid-stack-item'da çalışan animasyon kalmayınca döngüden çıkar. Bu bir
  # kör `sleep` değildir — her iterasyonda gerçek DOM durumunu sorgular ve
  # koşul sağlanır sağlanmaz devam eder; `timeout` sadece bir üst sınırdır
  # (tarayıcı `getAnimations` desteklemiyorsa veya beklenmedik şekilde takılı
  # kalırsa sonsuz döngüyü önler).
  def wait_for_grid_stack_layout_to_settle(timeout: 5)
    deadline = Time.now + timeout
    loop do
      still_animating = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.grid-stack-item')).some(function (el) {
          return typeof el.getAnimations === 'function' && el.getAnimations().length > 0;
        });
      JS
      break unless still_animating
      break if Time.now > deadline

      sleep 0.05
    end
  end
end
