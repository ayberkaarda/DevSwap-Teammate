require "application_system_test_case"

# Profil ızgarasının (Gridstack tabanlı profil widget grid'i) gerçek bir
# tarayıcıda uçtan uca çalıştığını doğrular. Özellikle Bug 1 regresyonunu
# yakalar: profile-grid controller eklenmezse Gridstack init olmaz ve tüm
# .grid-stack-item'lar CSS'te position:absolute; top:0; left:0 kalıp ÜST ÜSTE
# ("iç içe") yığılır. Bu test, Gridstack'in widget'ları GERÇEKTEN ayrık,
# çakışmayan piksel konumlarına yerleştirdiğini bounding box ölçerek kanıtlar.
# Ayrıca A+/A- yazı ölçeği kontrolünün (zoom) görünür etki yarattığını doğrular.
class ProfileGridTest < ApplicationSystemTestCase
  DEMO_EMAIL = "profile-grid-demo@devswap.com"
  MOCK_UID = "demo-profile-grid"

  def setup
    @demo_user = User.find_or_create_by!(email: DEMO_EMAIL) do |u|
      u.name = "ProfilDemo"
      u.terms_accepted_at = Time.current
    end
    @original_provider = @demo_user.provider
    @original_uid = @demo_user.uid

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
      provider: "github",
      uid: MOCK_UID,
      info: { name: "ProfilDemo", email: DEMO_EMAIL, image: nil, nickname: "profil-demo" },
      credentials: { token: "fake-token" }
    })

    @demo_user.update!(provider: "github", uid: MOCK_UID, terms_accepted_at: Time.current)
    ProfileWidget.where(user: @demo_user).destroy_all
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false

    @demo_user&.reload&.update!(provider: @original_provider, uid: @original_uid)
    ProfileWidget.where(user: @demo_user).destroy_all
    @demo_user&.destroy
  end

  test "profil ızgarası Gridstack ile ayrık, çakışmayan konumlara yerleşir" do
    visit root_path
    click_on "GitHub ile Giriş Yap"
    assert_current_path root_path

    visit public_profile_path(@demo_user)

    # Izgara ve widget'lar render edilmeli.
    assert_selector ".grid-stack"
    assert_selector ".grid-stack-item", minimum: 2

    # Gridstack init'inin DOM'a konum uygulamasını bekle: her item'in
    # sol/üst inline stili (veya transform) 0'dan farklı bir dağılım almalı.
    # Bounding box'ları tarayıcıdan oku.
    boxes = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.grid-stack > .grid-stack-item')).map(function (el) {
        var r = el.getBoundingClientRect();
        return { left: r.left, top: r.top, right: r.right, bottom: r.bottom };
      });
    JS

    assert_operator boxes.length, :>=, 2, "en az iki widget beklenir"

    # Hiçbir iki widget kutusu ANLAMLI ölçüde çakışmamalı. Gridstack margin'i
    # (8px) nedeniyle küçük komşuluk toleransı bırakıyoruz; gerçek "iç içe" hata
    # durumunda kutular neredeyse birebir üst üste biner (kesişim alanı büyük).
    tolerance = 4.0
    boxes.combination(2).each do |a, b|
      overlap_w = [ a["right"], b["right"] ].min - [ a["left"], b["left"] ].max
      overlap_h = [ a["bottom"], b["bottom"] ].min - [ a["top"], b["top"] ].max
      overlapping = overlap_w > tolerance && overlap_h > tolerance
      assert_not overlapping,
                 "profil widget'ları çakışıyor (Bug 1: Gridstack init olmadı?): #{a.inspect} vs #{b.inspect}"
    end

    # Widget'ların hepsi tam olarak (0,0)'da yığılmamış olmalı: en az iki farklı
    # sol VEYA üst değeri bulunmalı.
    distinct_positions = boxes.map { |bx| [ bx["left"].round, bx["top"].round ] }.uniq
    assert_operator distinct_positions.length, :>=, 2,
                    "tüm widget'lar aynı konumda (üst üste yığılmış)"
  end

  test "A+ yazı ölçeği kontrolü widget içeriğini görünür biçimde büyütür" do
    visit root_path
    click_on "GitHub ile Giriş Yap"
    visit public_profile_path(@demo_user)

    assert_button "Düzenle"
    click_on "Düzenle"

    # Edit modunda A+ butonları görünür olur. İlk widget'ın zoom ölçeğini oku,
    # A+ tıkla, artmış olmalı (yazı ölçeği düzeltmesi — zoom).
    before = page.evaluate_script(<<~JS)
      (function () {
        var c = document.querySelector('.grid-stack-item .grid-stack-item-content');
        return parseFloat(getComputedStyle(c).zoom) || 1;
      })();
    JS

    within first(".grid-stack-item") do
      click_button "A+"
    end

    # Zoom değerinin arttığını doğrula (persist PATCH ayrıca sunucuya gider).
    assert page.has_no_css?(".nonexistent", wait: 0.3) # kısa yerleşme beklemesi
    after = page.evaluate_script(<<~JS)
      (function () {
        var c = document.querySelector('.grid-stack-item .grid-stack-item-content');
        return parseFloat(getComputedStyle(c).zoom) || 1;
      })();
    JS

    assert_operator after, :>, before,
                    "A+ tıklandıktan sonra widget zoom ölçeği artmalı (yazı ölçeği çalışmıyor)"
  end
end
