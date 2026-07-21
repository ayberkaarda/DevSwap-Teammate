require "test_helper"

class Admin::WidgetResetsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan dashboard sifirlayamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "wr-member", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t1", terms_accepted_at: Time.current)
    DashboardWidget.seed_defaults_for(target)
    sign_in_via_github(member)

    assert_no_difference "ActivityLog.count" do
      post reset_dashboard_admin_widget_resets_path(user_id: target.id)
    end
    assert_redirected_to root_path
  end

  test "admin olmayan profil sifirlayamaz" do
    member = User.create!(name: "Uye", provider: "github", uid: "wr-member2", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t2", terms_accepted_at: Time.current)
    ProfileWidget.seed_defaults_for(target)
    sign_in_via_github(member)

    assert_no_difference "ActivityLog.count" do
      post reset_profile_admin_widget_resets_path(user_id: target.id)
    end
    assert_redirected_to root_path
  end

  test "admin hedef kullanicinin dashboard yerlesimini varsayilana sifirlar" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t3", terms_accepted_at: Time.current)
    # Kullanicinin ozellestirmesi: sadece TEK bir widget, taninabilir bozuk konumda.
    target.dashboard_widgets.create!(widget_type: "chatbox", position_x: 11, position_y: 42, width: 1, height: 1, visible: false)
    sign_in_via_github(admin)

    post reset_dashboard_admin_widget_resets_path(user_id: target.id)

    target.reload
    # Varsayilan yerlesim kadar widget, dogru turlerle geri gelmeli.
    assert_equal DashboardWidget::DEFAULT_LAYOUT.length, target.dashboard_widgets.count
    assert_equal DashboardWidget::DEFAULT_LAYOUT.map { |a| a[:widget_type] }.sort,
                 target.dashboard_widgets.pluck(:widget_type).sort
    # Ozellestirme (bozuk konum) gitmis olmali — chatbox varsayilan konumuna donmeli.
    chatbox = target.dashboard_widgets.find_by(widget_type: "chatbox")
    default_chatbox = DashboardWidget::DEFAULT_LAYOUT.find { |a| a[:widget_type] == "chatbox" }
    assert_equal default_chatbox[:position_x], chatbox.position_x
    assert_equal default_chatbox[:position_y], chatbox.position_y
    assert_equal default_chatbox[:visible], chatbox.visible

    assert_redirected_to telemetry_path
  end

  test "admin hedef kullanicinin profil yerlesimini varsayilana sifirlar" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin2", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t4", terms_accepted_at: Time.current)
    ProfileWidget.create!(user: target, widget_type: "identity", position_x: 9, position_y: 33, width: 2, height: 2, visible: false)
    sign_in_via_github(admin)

    post reset_profile_admin_widget_resets_path(user_id: target.id)

    assert_equal ProfileWidget::DEFAULT_LAYOUT.length, ProfileWidget.where(user: target).count
    assert_equal ProfileWidget::DEFAULT_LAYOUT.map { |a| a[:widget_type] }.sort,
                 ProfileWidget.where(user: target).pluck(:widget_type).sort
    identity = ProfileWidget.where(user: target).find_by(widget_type: "identity")
    default_identity = ProfileWidget::DEFAULT_LAYOUT.find { |a| a[:widget_type] == "identity" }
    assert_equal default_identity[:position_x], identity.position_x
    assert_equal default_identity[:position_y], identity.position_y

    assert_redirected_to telemetry_path
  end

  test "korumali hesabin dashboard yerlesimi de sifirlanabilir (moderasyon degil)" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin3", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu", provider: "github", uid: "wr-protected", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    protected_user.dashboard_widgets.create!(widget_type: "chatbox", position_x: 11, position_y: 42, width: 1, height: 1, visible: false)
    sign_in_via_github(admin)

    post reset_dashboard_admin_widget_resets_path(user_id: protected_user.id)

    protected_user.reload
    # Engellenmemeli: varsayilan yerlesim geri gelmis olmali.
    assert_equal DashboardWidget::DEFAULT_LAYOUT.length, protected_user.dashboard_widgets.count
    assert_redirected_to telemetry_path
    assert_nil flash[:alert]
  end

  test "korumali hesabin profil yerlesimi de sifirlanabilir (moderasyon degil)" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin4", role: "admin", terms_accepted_at: Time.current)
    protected_user = User.create!(name: "Kurucu", provider: "github", uid: "wr-protected2", role: "admin", protected_from_moderation: true, terms_accepted_at: Time.current)
    ProfileWidget.create!(user: protected_user, widget_type: "identity", position_x: 9, position_y: 33, width: 2, height: 2, visible: false)
    sign_in_via_github(admin)

    post reset_profile_admin_widget_resets_path(user_id: protected_user.id)

    assert_equal ProfileWidget::DEFAULT_LAYOUT.length, ProfileWidget.where(user: protected_user).count
    assert_redirected_to telemetry_path
    assert_nil flash[:alert]
  end

  test "dashboard sifirlama dogru action_type ile ActivityLog olusturur" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin5", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t5", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "ActivityLog.count", 1 do
      post reset_dashboard_admin_widget_resets_path(user_id: target.id)
    end
    log = ActivityLog.last
    assert_equal "admin_dashboard_widgets_reset", log.action_type
    assert_equal admin, log.user
  end

  test "profil sifirlama dogru action_type ile ActivityLog olusturur" do
    admin = User.create!(name: "Root", provider: "github", uid: "wr-admin6", role: "admin", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "wr-t6", terms_accepted_at: Time.current)
    sign_in_via_github(admin)

    assert_difference "ActivityLog.count", 1 do
      post reset_profile_admin_widget_resets_path(user_id: target.id)
    end
    log = ActivityLog.last
    assert_equal "admin_profile_widgets_reset", log.action_type
    assert_equal admin, log.user
  end

  private

  def sign_in_via_github(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.uid,
      info: { name: user.name, email: user.email, nickname: user.uid, image: nil },
      credentials: { token: "test-token" }
    )

    get "/auth/github/callback"
  end
end
