require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true

    @author = User.create!(name: "Yazar", provider: "github", uid: "nc-author", terms_accepted_at: Time.current)
    @user_a = User.create!(name: "Kullanici A", provider: "github", uid: "nc-a", terms_accepted_at: Time.current)
    @user_b = User.create!(name: "Kullanici B", provider: "github", uid: "nc-b", terms_accepted_at: Time.current)

    @skill = Skill.create!(name: "Rust", category: "language")
    @post = Post.create!(user: @author, content: "Rust super.", title: "Test")

    @notif_a = PostNotification.create!(post: @post, user: @user_a, skill: @skill)
    @notif_b = PostNotification.create!(post: @post, user: @user_b, skill: @skill)
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "dismiss sadece o bildirimi kapatir" do
    sign_in_via_github(@user_a)

    patch dismiss_notification_path(@notif_a)

    assert @notif_a.reload.dismissed_at.present?, "hedef bildirim dismiss edilmeli"
    assert_nil @notif_b.reload.dismissed_at, "diger kullanicinin bildirimi etkilenmemeli"
    assert_nil @notif_a.claimed_at, "dismiss claim etmemeli"
  end

  test "claim o bildirimi ve ayni posta ait tum diger aktif bildirimleri dismiss eder (cascade)" do
    sign_in_via_github(@user_a)

    patch claim_notification_path(@notif_a)

    @notif_a.reload
    @notif_b.reload

    assert @notif_a.dismissed_at.present?, "claim edilen bildirim dismiss edilmeli"
    assert @notif_a.claimed_at.present?, "claim edilen bildirim claimed olmali"
    assert @notif_b.dismissed_at.present?, "ayni posta ait diger bildirim de dismiss edilmeli (cascade)"
    assert_nil @notif_b.claimed_at, "cascade dismiss digerlerini claim etmemeli"
  end

  test "baska kullanicinin bildirimini dismiss etmeye calisinca bulunamaz" do
    sign_in_via_github(@user_a)

    patch dismiss_notification_path(@notif_b)

    assert_response :not_found
    assert_nil @notif_b.reload.dismissed_at, "baska kullanicinin bildirimi degismemeli"
  end

  test "baska kullanicinin bildirimini claim etmeye calisinca bulunamaz" do
    sign_in_via_github(@user_a)

    patch claim_notification_path(@notif_b)

    assert_response :not_found
    assert_nil @notif_b.reload.claimed_at, "baska kullanicinin bildirimi claim edilmemeli"
  end

  test "giris yapmadan erisim reddedilir" do
    patch dismiss_notification_path(@notif_a)

    assert_redirected_to root_path
    assert_nil @notif_a.reload.dismissed_at
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
