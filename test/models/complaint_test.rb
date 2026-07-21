require "test_helper"

class ComplaintTest < ActiveSupport::TestCase
  def build_users
    reporter = User.create!(name: "Sik Bildiren", provider: "github", uid: "cm-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)
    target = User.create!(name: "Sik Hedef", provider: "github", uid: "cm-#{SecureRandom.hex(4)}", terms_accepted_at: Time.current)
    [ reporter, target ]
  end

  test "description olmadan gecersizdir" do
    reporter, target = build_users
    complaint = Complaint.new(reported_by: reporter, target_user: target)
    assert_not complaint.valid?
    assert_includes complaint.errors[:description], "can't be blank"
  end

  test "gecerli sikayet kaydedilir ve iliskiler cozulur" do
    reporter, target = build_users
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "kotu davranis")
    assert_equal reporter, complaint.reported_by
    assert_equal target, complaint.target_user
  end

  test "evidence_photo eklenebilir" do
    reporter, target = build_users
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "kanit ekli")
    complaint.evidence_photo.attach(io: StringIO.new("fake-image"), filename: "kanit.png", content_type: "image/png")
    assert complaint.evidence_photo.attached?
  end

  test "yeni sikayet varsayilan olarak pending statusundedir" do
    reporter, target = build_users
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "durum testi")
    assert_equal "pending", complaint.status
  end

  test "gecersiz status reddedilir" do
    reporter, target = build_users
    complaint = Complaint.new(reported_by: reporter, target_user: target, description: "x", status: "sacma")
    assert_not complaint.valid?
    assert_includes complaint.errors[:status], "is not included in the list"
  end

  test "bos status reddedilir" do
    reporter, target = build_users
    complaint = Complaint.new(reported_by: reporter, target_user: target, description: "x", status: "")
    assert_not complaint.valid?
    assert_includes complaint.errors[:status], "can't be blank"
  end

  test "pending scope yalnizca beklemedeki sikayetleri dondurur" do
    reporter, target = build_users
    pending_c = Complaint.create!(reported_by: reporter, target_user: target, description: "beklemede")
    reviewed_c = Complaint.create!(reported_by: reporter, target_user: target, description: "incelendi", status: "reviewed")
    assert_includes Complaint.pending, pending_c
    assert_not_includes Complaint.pending, reviewed_c
  end
end
