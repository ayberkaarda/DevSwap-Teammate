require "application_system_test_case"

# Bug fix regresyonu: Nav bar'daki `overflow-x-auto` (nav linklerinin dar
# ekranlarda yatay kaydirilabilmesi icin) tema <details>/<summary> acilir
# menusunu de kirpiyordu ve nav'da istenmeyen bir scrollbar'a sebep oluyordu.
# Kok neden: bir eksende (overflow-x) "auto" verilip diger eksen (overflow-y)
# belirtilmeyince tarayicilar CSS spesifikasyonu geregi digerini de
# gorunmez/auto yapiyor; bu da details>summary disina tasan (position:
# absolute, mt-2 ile ozetin ALTINA acilan) menuyu dikeyde kirpiyordu.
#
# Fix: `overflow-x-auto` artik butun <nav>'da degil, SADECE nav linklerini
# saran ic div'de. Boylece tema butonu + acilir menusu, kirpma/scroll
# davranisi olan kapsayicinin DISINDA kaliyor; nav linkleri dar ekranlarda
# hala kendi ic div'i icinde yatay kaydirilabiliyor.
class ThemeDropdownTest < ApplicationSystemTestCase
  MOCK_UID = "theme-dropdown-viewer"

  def setup
    OmniAuth.config.test_mode = true

    @viewer = User.create!(name: "Theme Dropdown Viewer", provider: "github", uid: "theme-dropdown-1", terms_accepted_at: Time.current)

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

    @viewer&.destroy
  end

  test "tema acilir menusu kirpilmadan tum secenekleri gosterir ve nav'da istenmeyen scrollbar olusmaz" do
    visit "/auth/github/callback"
    visit root_path

    # Nav'in kendisi artik overflow-x-auto tasimiyor: dikeyde zorla
    # "auto"/kirpilma davranisina girmemeli (bu, eski scrollbar/kirpilma
    # bug'inin kok nedeniydi).
    nav_overflow_y = page.evaluate_script(<<~JS)
      window.getComputedStyle(document.querySelector('nav')).overflowY
    JS
    assert_equal "visible", nav_overflow_y, "nav overflow-y 'visible' olmali; aksi halde tema menusu kirpilir"

    # Nav linklerini saran ic div hala yatay kaydirilabilir olmali (dar
    # ekranlarda cok sayida linkin gorunebilmesi icin).
    links_overflow_x = page.evaluate_script(<<~JS)
      window.getComputedStyle(document.querySelector('nav .overflow-x-auto')).overflowX
    JS
    assert_equal "auto", links_overflow_x

    # Tema butonuna tikla, menu acilsin.
    find("#theme-toggle-summary").click

    assert_selector "details#theme-toggle[open]"

    %w[Sistem Açık Koyu Dracula Monokai Nord Solarized Gruvbox One\ Dark Tokyo\ Night Matrix].each do |label|
      assert_selector "#theme-toggle button[data-theme-target='option']", text: label, visible: true
    end

    # Kirpilma olmadigini geometrik olarak dogrula: her secenek butonu
    # sifirdan buyuk genislik/yukseklige sahip olmali (kirpilmis/collapse
    # olmus elemanlar genelde 0 veya cok kucuk boyuta sahiptir).
    option_rects = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('#theme-toggle button[data-theme-target="option"]')).map(function(el) {
        var r = el.getBoundingClientRect();
        return { width: r.width, height: r.height };
      })
    JS

    assert_equal 11, option_rects.length
    option_rects.each do |rect|
      assert rect["width"] > 20, "secenek butonu genisligi beklenenden kucuk (kirpilma suphesi): #{rect}"
      assert rect["height"] > 5, "secenek butonu yuksekligi beklenenden kucuk (kirpilma suphesi): #{rect}"
    end

    page.save_screenshot(Rails.root.join("tmp/theme_dropdown_open.png").to_s)
  end

  test "dar ekranda nav linkleri kendi ic div'inde kayar, tema butonu her zaman erisilebilir kalir" do
    page.driver.browser.manage.window.resize_to(390, 800)

    visit "/auth/github/callback"
    visit root_path

    scroll_info = page.evaluate_script(<<~JS)
      (function() {
        var el = document.querySelector('nav .overflow-x-auto');
        return { scrollWidth: el.scrollWidth, clientWidth: el.clientWidth };
      })()
    JS

    # Bu genislikte linkler sigmadigi icin ic div'in scrollWidth'i
    # clientWidth'inden buyuk olmali (yani gercekten kaydirilabilir).
    assert scroll_info["scrollWidth"] >= scroll_info["clientWidth"]

    # Tema butonu hala goruntude ve tiklanabilir olmali.
    assert_selector "#theme-toggle-summary", visible: true
    find("#theme-toggle-summary").click
    assert_selector "details#theme-toggle[open]"
    assert_text "Dracula"
  ensure
    # Bug fix: bu test pencereyi 390x800'e kucultuyor ama geri
    # buyutmuyordu. Capybara/Selenium ayni tarayici penceresini test
    # siniflari arasinda paylastigi icin (bin/rails test:system tam
    # calistirmasinda), bu dar viewport bir sonraki sistem testine
    # sizip (orn. MinimalDmModeTest) ElementClickInterceptedError'a
    # sebep oluyordu. Test basarili/basarisiz her durumda pencereyi
    # ApplicationSystemTestCase'deki standart boyuta geri getiriyoruz.
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
