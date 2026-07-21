require "test_helper"

class Admin::ComplaintsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "admin olmayan uye sikayet panelini goremez" do
    member = User.create!(name: "Uye", provider: "github", uid: "ac-member", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(member)

    get admin_complaints_path

    assert_redirected_to root_path
  end

  test "moderator sikayet panelini goremez (require_admin)" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "ac-mod", role: "moderator", terms_accepted_at: Time.current)
    sign_in_via_github(mod)

    get admin_complaints_path

    assert_redirected_to root_path
  end

  test "admin sikayet index'ini gorebilir ve sikayetler listelenir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-1", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target", role: "member", terms_accepted_at: Time.current)
    Complaint.create!(reported_by: reporter, target_user: target, description: "Listelenecek sikayet aciklamasi", status: "pending")
    sign_in_via_github(admin)

    get admin_complaints_path

    assert_response :success
    assert_match "Listelenecek sikayet aciklamasi", response.body
  end

  test "status filtresi sadece o durumdaki sikayetleri dondurur" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-2", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-2", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-2", role: "member", terms_accepted_at: Time.current)
    Complaint.create!(reported_by: reporter, target_user: target, description: "Bekleyen sikayet metni", status: "pending")
    Complaint.create!(reported_by: reporter, target_user: target, description: "Reddedilmis sikayet metni", status: "dismissed")
    sign_in_via_github(admin)

    get admin_complaints_path, params: { status: "dismissed" }

    assert_response :success
    assert_match "Reddedilmis sikayet metni", response.body
    assert_no_match "Bekleyen sikayet metni", response.body
  end

  test "admin bir sikayeti incelendi olarak isaretleyebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-3", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-3", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-3", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Incelenecek sikayet", status: "pending")
    sign_in_via_github(admin)

    assert_difference "ActivityLog.count", 1 do
      patch mark_reviewed_admin_complaint_path(complaint), params: { status: "pending" }
    end

    assert_redirected_to admin_complaints_path(status: "pending")
    assert_equal "reviewed", complaint.reload.status
    assert_equal "Şikayet incelendi olarak işaretlendi.", flash[:notice]
  end

  test "admin bir sikayeti reddedebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-4", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-4", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-4", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Reddedilecek sikayet", status: "pending")
    sign_in_via_github(admin)

    assert_difference "ActivityLog.count", 1 do
      patch dismiss_admin_complaint_path(complaint)
    end

    assert_redirected_to admin_complaints_path
    assert_equal "dismissed", complaint.reload.status
    assert_equal "Şikayet reddedildi.", flash[:notice]
  end

  test "admin bir sikayet icin islem yapabilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-5", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-5", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-5", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Islem yapilacak sikayet", status: "reviewed")
    sign_in_via_github(admin)

    assert_difference "ActivityLog.count", 1 do
      patch mark_actioned_admin_complaint_path(complaint)
    end

    assert_redirected_to admin_complaints_path
    assert_equal "actioned", complaint.reload.status
    assert_equal "Şikayet işlem yapıldı olarak işaretlendi.", flash[:notice]
  end

  test "admin bir sikayeti kalici olarak silebilir" do
    admin = User.create!(name: "Root", provider: "github", uid: "ac-admin-6", role: "admin", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-6", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-6", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Silinecek sikayet", status: "pending")
    sign_in_via_github(admin)

    assert_difference "Complaint.count", -1 do
      assert_difference "ActivityLog.count", 1 do
        delete admin_complaint_path(complaint)
      end
    end

    assert_redirected_to admin_complaints_path
    assert_equal "Şikayet kalıcı olarak silindi.", flash[:notice]
    assert_not Complaint.exists?(complaint.id)
  end

  test "moderator sikayet silemez" do
    mod = User.create!(name: "Moderator", provider: "github", uid: "ac-mod-6", role: "moderator", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-7", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-7", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Silinmeyecek sikayet", status: "pending")
    sign_in_via_github(mod)

    delete admin_complaint_path(complaint)

    assert_redirected_to root_path
    assert Complaint.exists?(complaint.id)
  end

  test "uye sikayet silemez" do
    member = User.create!(name: "Uye", provider: "github", uid: "ac-member-6", role: "member", terms_accepted_at: Time.current)
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "ac-reporter-8", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "ac-target-8", role: "member", terms_accepted_at: Time.current)
    complaint = Complaint.create!(reported_by: reporter, target_user: target, description: "Silinmeyecek sikayet 2", status: "pending")
    sign_in_via_github(member)

    delete admin_complaint_path(complaint)

    assert_redirected_to root_path
    assert Complaint.exists?(complaint.id)
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
