require "test_helper"

class EscalationTest < ActiveSupport::TestCase
  def build_users
    reporter = User.create!(name: "Esk Bildiren", provider: "github", uid: "es-#{SecureRandom.hex(4)}", role: "moderator", terms_accepted_at: Time.current)
    target = User.create!(name: "Esk Hedef", provider: "github", uid: "es-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)
    [ reporter, target ]
  end

  test "description olmadan gecersizdir" do
    reporter, target = build_users
    escalation = Escalation.new(reported_by: reporter, target_user: target)
    assert_not escalation.valid?
    assert_includes escalation.errors[:description], "can't be blank"
  end

  test "status varsayilani pending" do
    reporter, target = build_users
    escalation = Escalation.create!(reported_by: reporter, target_user: target, description: "banlanmali")
    assert_equal "pending", escalation.status
  end

  test "evidence_photo eklenebilir" do
    reporter, target = build_users
    escalation = Escalation.create!(reported_by: reporter, target_user: target, description: "kanit ekli")
    escalation.evidence_photo.attach(io: StringIO.new("fake-image"), filename: "kanit.png", content_type: "image/png")
    assert escalation.evidence_photo.attached?
  end
end
