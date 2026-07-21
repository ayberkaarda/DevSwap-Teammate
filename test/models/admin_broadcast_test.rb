require "test_helper"

class AdminBroadcastTest < ActiveSupport::TestCase
  def admin!(uid)
    User.create!(name: "Admin-#{uid}", provider: "github", uid: uid, role: "admin", terms_accepted_at: Time.current)
  end

  test "active scope suresiz (expires_at nil) duyurulari icerir" do
    admin = admin!("ab-model-1")
    broadcast = AdminBroadcast.create!(admin: admin, message: "suresiz", expires_at: nil)

    assert_includes AdminBroadcast.active, broadcast
  end

  test "active scope gelecekte sona erecek duyurulari icerir" do
    admin = admin!("ab-model-2")
    broadcast = AdminBroadcast.create!(admin: admin, message: "gelecekte biter", expires_at: 1.hour.from_now)

    assert_includes AdminBroadcast.active, broadcast
  end

  test "active scope suresi gecmis duyurulari haric tutar" do
    admin = admin!("ab-model-3")
    broadcast = AdminBroadcast.create!(admin: admin, message: "suresi gecti", expires_at: 1.hour.ago)

    assert_not_includes AdminBroadcast.active, broadcast
  end

  test "expired? expires_at nil ise false doner" do
    admin = admin!("ab-model-4")
    broadcast = AdminBroadcast.create!(admin: admin, message: "suresiz", expires_at: nil)

    assert_not broadcast.expired?
  end

  test "expired? expires_at gelecekte ise false doner" do
    admin = admin!("ab-model-5")
    broadcast = AdminBroadcast.create!(admin: admin, message: "gelecekte biter", expires_at: 1.hour.from_now)

    assert_not broadcast.expired?
  end

  test "expired? expires_at gecmiste ise true doner" do
    admin = admin!("ab-model-6")
    broadcast = AdminBroadcast.create!(admin: admin, message: "suresi gecti", expires_at: 1.hour.ago)

    assert broadcast.expired?
  end
end
