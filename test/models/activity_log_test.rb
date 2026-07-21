require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "record! kullanıcı için activity log olusturur" do
    user = users(:one)

    assert_difference "ActivityLog.count", 1 do
      ActivityLog.record!(user, "login", "#{user.name} giriş yaptı.")
    end

    log = ActivityLog.last
    assert_equal user, log.user
    assert_equal "login", log.action_type
    assert_equal "#{user.name} giriş yaptı.", log.detail
  end

  test "record! user nil ise sessizce hicbir sey yapmaz" do
    assert_no_difference "ActivityLog.count" do
      ActivityLog.record!(nil, "login", "hayalet giris")
    end
  end

  test "recent scope en yeni once siralar" do
    user = users(:one)
    older = ActivityLog.create!(user: user, action_type: "login", detail: "eski", created_at: 2.days.ago)
    newer = ActivityLog.create!(user: user, action_type: "login", detail: "yeni", created_at: 1.hour.ago)

    assert_equal [ newer, older ], user.activity_logs.recent.to_a
  end

  test "admin? role admin oldugunda true doner" do
    assert users(:one).admin?
    refute users(:two).admin?
  end
end
