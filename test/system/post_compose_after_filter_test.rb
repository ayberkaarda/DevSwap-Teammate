require "application_system_test_case"

# Regresyon: Akis sayfasinda arama/siralama/aralik filtreleriyle (Turbo Drive
# GET gezinmeleri, URL query string'ini degistirir) etkilesime girdikten SONRA
# ustteki compose formunun ("POST OLUSTUR") calismaya devam etmesi gerekir.
#
# Gecmis bug (kok neden): infinite_scroll_controller.js, IntersectionObserver'i
# yalnizca connect()'te kuruyordu. Turbo Drive'in snapshot onbellegi (preview)
# ile bir filtre gezinmesi sonrasi Stimulus, `sentinelTargetConnected`/
# `Disconnected` geri cagrilarini connect() calismadan tetikliyor; `this.observer`
# undefined oldugundan `.observe()/.unobserve()` YAKALANMAYAN bir TypeError
# firlatiyordu. Bu hata, Stimulus'un ayni mutasyon yigininindaki KALAN
# controller'lari baglamasini yarida kesiyor ve compose formunun tag-picker'i
# olu kaliyordu (etiket eklenemiyor, kullanici gozunde "Yayinla bir sey yapmiyor").
#
# Bu test filtrelerle gezindikten sonra: (1) sayfada yakalanmayan JS hatasi
# olmamali, (2) tag-picker canli olmali (etiket yazinca chip + gizli skill_ids[]
# input'u olusmali), (3) compose formu gercekten post olusturmali.
class PostComposeAfterFilterTest < ApplicationSystemTestCase
  MOCK_UID = "post-compose-after-filter-user"

  def setup
    OmniAuth.config.test_mode = true

    @user = User.create!(
      name: "Filter Compose Tester",
      provider: "github",
      uid: MOCK_UID,
      terms_accepted_at: Time.current
    )

    @skill = Skill.find_or_create_by!(name: "React") { |s| s.category = "frontend_framework" }

    # Sentinel'in gercekten gozlemlenmesi (ve eski bug'in tetiklenmesi) icin
    # birden fazla sayfaya yetecek kadar seed post.
    22.times { |i| Post.create!(content: "SEED_POST_#{i}", user: @user, created_at: i.minutes.ago) }

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: MOCK_UID,
      info: { name: @user.name, email: @user.email, nickname: MOCK_UID, image: nil },
      credentials: { token: "test-token" }
    )
  end

  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
    Post.where(user: @user).destroy_all if @user
    @user&.destroy
  end

  test "filtrelerle gezindikten sonra compose formu (tag-picker dahil) calisir" do
    visit "/auth/github/callback"
    visit posts_path

    # Yakalanmayan JS hatalarini window uzerinde topla (Turbo Drive body
    # degisimlerinden bagimsiz kalmasi icin window'a bagli).
    page.execute_script(<<~JS)
      window.__jsErrors = [];
      window.addEventListener('error', function(e){
        window.__jsErrors.push((e.message || '') + ' @ ' + (e.filename || ''));
      }, true);
    JS

    # Siralama + aralik filtreleriyle Turbo Drive gezinmeleri; ayni sayfayi
    # tekrar ziyaret ederek Turbo'nun snapshot preview'ini de devreye sok
    # (eski bug tam da bu preview yolunda connect()'i atliyordu).
    click_on "En çok beğenilen"
    click_on "En son"
    click_on "En çok beğenilen"
    click_on "Bu hafta"

    assert_selector "#post-compose"

    within "#post-compose" do
      fill_in "content", with: "COMPOSE_AFTER_FILTER_POSTU"

      # Tag-picker canli mi? Skill adini yazip Enter'a basinca chip + gizli
      # skill_ids[] input'u olusmali (bug varken bu OLUSMUYORDU).
      picker = find("input[data-tag-picker-target='input']")
      picker.set(@skill.name)
      picker.send_keys(:enter)

      within "[data-tag-picker-target='chips']" do
        assert_text @skill.name
        assert_selector "input[type='hidden'][name='skill_ids[]'][value='#{@skill.id}']", visible: :all
      end

      click_on "Yayınla"
    end

    # Post sayfa yenilenmeden listeye eklendi mi?
    assert_selector "#posts-list", text: "COMPOSE_AFTER_FILTER_POSTU"

    # Filtre gezinmeleri sirasinda hicbir yakalanmayan JS hatasi olmamali.
    js_errors = page.evaluate_script("window.__jsErrors || []")
    assert_empty js_errors, "Filtre gezinmesi sonrasi yakalanmayan JS hatasi olustu: #{js_errors.inspect}"

    # Post gercekten olustu ve dogru skill ile etiketlendi mi?
    post = Post.where(user: @user, content: "COMPOSE_AFTER_FILTER_POSTU").first
    assert_not_nil post
    assert_includes post.skills.map(&:name), @skill.name
  end
end
