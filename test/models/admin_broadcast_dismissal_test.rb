require "test_helper"

class AdminBroadcastDismissalTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(name: "Root Duyuru", provider: "github", uid: "abd-admin", role: "admin", terms_accepted_at: Time.current)
    @user = User.create!(name: "Kapatan Kullanici", provider: "github", uid: "abd-user", terms_accepted_at: Time.current)
    @broadcast = AdminBroadcast.create!(admin: @admin, message: "Test duyurusu")
  end

  test "dismiss! bir kayit olusturur" do
    assert_difference "AdminBroadcastDismissal.count", 1 do
      AdminBroadcastDismissal.dismiss!(@user, @broadcast)
    end

    dismissal = AdminBroadcastDismissal.find_by(user: @user, admin_broadcast: @broadcast)
    assert_not_nil dismissal
  end

  test "dismiss! ikinci cagri yeni kayit uretmez (idempotent)" do
    first = AdminBroadcastDismissal.dismiss!(@user, @broadcast)

    assert_no_difference "AdminBroadcastDismissal.count" do
      second = AdminBroadcastDismissal.dismiss!(@user, @broadcast)
      assert_equal first.id, second.id
    end
  end

  test "dismissed_broadcast_ids_for kapatilan duyurunun id'sini dondurur" do
    AdminBroadcastDismissal.dismiss!(@user, @broadcast)

    assert_includes AdminBroadcastDismissal.dismissed_broadcast_ids_for(@user), @broadcast.id
  end

  test "kapatma per-user'dir: bir kullanicinin kapatmasi digerini etkilemez" do
    other = User.create!(name: "Diger Kullanici", provider: "github", uid: "abd-other", terms_accepted_at: Time.current)
    AdminBroadcastDismissal.dismiss!(@user, @broadcast)

    assert_includes AdminBroadcastDismissal.dismissed_broadcast_ids_for(@user), @broadcast.id
    assert_not_includes AdminBroadcastDismissal.dismissed_broadcast_ids_for(other), @broadcast.id
  end

  test "ayni user+broadcast icin ikinci kayit gecersizdir (uniqueness)" do
    AdminBroadcastDismissal.create!(user: @user, admin_broadcast: @broadcast)
    dup = AdminBroadcastDismissal.new(user: @user, admin_broadcast: @broadcast)

    assert_not dup.valid?
  end
end
