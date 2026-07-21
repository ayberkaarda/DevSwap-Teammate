require "test_helper"

class WarningTest < ActiveSupport::TestCase
  def build_users
    user = User.create!(name: "Uyari Hedef", provider: "github", uid: "wn-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)
    staff = User.create!(name: "Uyari Staff", provider: "github", uid: "wn-#{SecureRandom.hex(4)}", role: "moderator", terms_accepted_at: Time.current)
    [ user, staff ]
  end

  test "reason olmadan gecersizdir" do
    user, staff = build_users
    warning = UserWarning.new(user: user, issued_by: staff)
    assert_not warning.valid?
    assert_includes warning.errors[:reason], "can't be blank"
  end

  test "gecerli uyari kaydedilir ve iliskiler cozulur" do
    user, staff = build_users
    warning = UserWarning.create!(user: user, issued_by: staff, reason: "spam")
    assert_equal user, warning.user
    assert_equal staff, warning.issued_by
  end
end
