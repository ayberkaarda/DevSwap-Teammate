require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "baglanti kurulunca kullanici cevrimici (is_online: true) isaretlenir" do
    user = User.create!(name: "Presence On", provider: "github", uid: "conn-on", terms_accepted_at: Time.current, is_online: false)

    connect session: { user_id: user.id }

    assert_equal user, connection.current_user
    assert user.reload.is_online, "Baglanti kurulunca is_online true olmaliydi"
  end

  test "baglanti kesilince cevrimdisi (is_online: false) + last_seen_at set edilir" do
    user = User.create!(name: "Presence Off", provider: "github", uid: "conn-off", terms_accepted_at: Time.current, is_online: true)

    connect session: { user_id: user.id }
    assert user.reload.is_online

    freeze_time do
      disconnect

      user.reload
      assert_not user.is_online, "Baglanti kesilince is_online false olmaliydi"
      assert_equal Time.current, user.last_seen_at, "Baglanti kesilince last_seen_at set edilmeliydi"
    end
  end

  test "gecersiz oturum kimligi ile baglanti reddedilir" do
    assert_reject_connection do
      connect session: { user_id: -1 }
    end
  end
end
