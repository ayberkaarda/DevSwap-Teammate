require "test_helper"

class BannedAccountTest < ActiveSupport::TestCase
  test "banned? provider/uid bos ise false doner" do
    assert_not BannedAccount.banned?(nil, nil)
    assert_not BannedAccount.banned?("github", "")
    assert_not BannedAccount.banned?("", "some-uid")
  end

  test "banned? aktif bir ban varsa true doner" do
    BannedAccount.create!(provider: "github", uid: "ban-1", active: true, banned_by: users(:one))

    assert BannedAccount.banned?("github", "ban-1")
  end

  test "banned? pasif ban icin false doner" do
    BannedAccount.create!(provider: "github", uid: "ban-2", active: false, banned_by: users(:one))

    assert_not BannedAccount.banned?("github", "ban-2")
  end

  test "banned? suresi gecmis ban icin false doner" do
    BannedAccount.create!(provider: "github", uid: "ban-3", active: true, banned_until: 1.day.ago, banned_by: users(:one))

    assert_not BannedAccount.banned?("github", "ban-3")
  end

  test "banned? suresi dolmamis ban icin true doner" do
    BannedAccount.create!(provider: "github", uid: "ban-4", active: true, banned_until: 1.day.from_now, banned_by: users(:one))

    assert BannedAccount.banned?("github", "ban-4")
  end

  test "active scope sadece aktif ve suresi gecmemis banlari dondurur" do
    permanent = BannedAccount.create!(provider: "github", uid: "ban-5", active: true, banned_by: users(:one))
    expired = BannedAccount.create!(provider: "github", uid: "ban-6", active: true, banned_until: 1.day.ago, banned_by: users(:one))
    inactive = BannedAccount.create!(provider: "github", uid: "ban-7", active: false, banned_by: users(:one))

    assert_includes BannedAccount.active, permanent
    assert_not_includes BannedAccount.active, expired
    assert_not_includes BannedAccount.active, inactive
  end

  test "permanent? banned_until yoksa true doner" do
    ban = BannedAccount.new(banned_until: nil)
    assert ban.permanent?

    ban.banned_until = 1.day.from_now
    assert_not ban.permanent?
  end
end
