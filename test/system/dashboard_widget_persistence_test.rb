require "application_system_test_case"

# Bu test, dashboard grid'inin (Faz 31c, Gridstack tabanli) widget gizle/goster
# ("Gizle" ve gizli listesinden geri getirme) etkilesiminin sunucu tarafinda
# GERCEKTEN kalici oldugunu dogrular. test/system/dashboard_grid_test.rb zaten
# grid'in render edildigini ve edit modunun acildigini kapsiyor; bu dosya onu
# DEGISTIRMEDEN, eksik olan kalicilik (persistence) kapsamini ekler:
#   - "Gizle" tiklamasi widget'i grid'den kaldirir VE DashboardWidget#visible
#     alanini sunucuda false yapar.
#   - Gizli listesinden "+ widget_type" ile geri getirme, widget'i tekrar
#     gorunur/grid'de yapar VE DashboardWidget#visible alanini true yapar.
#
# NOT: Gercek Gridstack drag/resize piksel surukleme simulasyonu headless
# Selenium'da guvenilmez oldugu icin burada YAPILMIYOR; odak, gercek ve
# eksik olan hide/show round-trip'i.
class DashboardWidgetPersistenceTest < ApplicationSystemTestCase
  DEMO_EMAIL = "dashboard-widget-persistence-demo@devswap.com"
  MOCK_UID = "demo-dashboard-widget-persistence"

  def setup
    @demo_user = User.find_or_create_by!(email: DEMO_EMAIL) do |u|
      u.name = "Ayberk"
      u.terms_accepted_at = Time.current
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

    @demo_user.update!(
      provider: "github",
      uid: MOCK_UID,
      terms_accepted_at: Time.current
    )

    @demo_user.dashboard_widgets.destroy_all
    return if ChatRoom.public_rooms.exists?

    ChatRoom.find_or_create_by!(slug: "dashboard-widget-persistence-test-room") do |room|
      room.name = "Genel"
      room.private = false
      room.position = 1
    end
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = nil
    OmniAuth.config.test_mode = false

    @demo_user&.reload&.update!(provider: @original_provider, uid: @original_uid)
    @demo_user&.dashboard_widgets&.destroy_all
    @demo_user&.destroy
  end

  test "widget gizlemek grid'den kaldirir ve sunucuda visible false yapar" do
    visit root_path
    click_on "GitHub ile Giriş Yap"
    assert_current_path root_path

    widget = @demo_user.dashboard_widgets.find_by(widget_type: "match_algorithm")
    assert widget.present?
    assert widget.visible?

    click_on "Düzenle"
    assert_text "Bitir"

    within(".grid-stack-item[gs-id='#{widget.id}']") do
      click_on "Gizle"
    end

    # Grid'den kaldirildi (DOM'dan kayboldu).
    assert_no_selector ".grid-stack-item[gs-id='#{widget.id}']"

    # Sunucu tarafinda da kalici olarak gizlendi.
    assert_not widget.reload.visible
  end

  test "gizli widget'i listeden geri getirmek tekrar gorunur yapar" do
    visit root_path
    click_on "GitHub ile Giriş Yap"
    assert_current_path root_path

    hidden_widget = @demo_user.dashboard_widgets.find_by(widget_type: "weather")
    assert hidden_widget.present?
    assert_not hidden_widget.visible?

    click_on "Düzenle"
    assert_text "Bitir"

    within("[data-dashboard-grid-target='hiddenList']") do
      click_on "+ weather"
    end

    # showWidget chatbox disindaki turler icin sert sayfa yenilemesi tetikler;
    # sunucu tarafinda kalici oldugunu dogrulamak icin biraz bekleyip
    # (asenkron PATCH + reload) yeniden yukleniyor.
    assert_selector ".grid-stack", wait: 5

    assert hidden_widget.reload.visible
    assert_selector ".grid-stack-item[gs-id='#{hidden_widget.id}']"
  end
end
