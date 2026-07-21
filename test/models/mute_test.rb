require "test_helper"

class MuteTest < ActiveSupport::TestCase
  def build_users
    user = User.create!(name: "Mute Hedef", provider: "github", uid: "mt-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)
    staff = User.create!(name: "Mute Staff", provider: "github", uid: "mt-#{SecureRandom.hex(4)}", role: "moderator", terms_accepted_at: Time.current)
    [ user, staff ]
  end

  test "muted_until olmadan gecersizdir" do
    user, staff = build_users
    mute = Mute.new(user: user, muted_by: staff)
    assert_not mute.valid?
    assert_includes mute.errors[:muted_until], "can't be blank"
  end

  test "aktif ve suresi dolmamis mute active_for? true doner" do
    user, staff = build_users
    Mute.create!(user: user, muted_by: staff, muted_until: 1.hour.from_now, active: true)
    assert Mute.active_for?(user)
  end

  test "suresi dolmus mute artik aktif sayilmaz" do
    user, staff = build_users
    Mute.create!(user: user, muted_by: staff, muted_until: 1.hour.ago, active: true)
    assert_not Mute.active_for?(user)
  end

  test "pasif (active=false) mute aktif sayilmaz" do
    user, staff = build_users
    Mute.create!(user: user, muted_by: staff, muted_until: 1.hour.from_now, active: false)
    assert_not Mute.active_for?(user)
  end

  test "nil kullanici active_for? false doner" do
    assert_not Mute.active_for?(nil)
  end
end
