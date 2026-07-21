require "test_helper"

class ComplaintsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "giris yapmamis kullanici sikayet gonderemez" do
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-t0", terms_accepted_at: Time.current)

    assert_no_difference "Complaint.count" do
      post complaints_path, params: { target_user_id: target.id, description: "test" }
    end
    assert_redirected_to root_path
  end

  test "giris yapmis kullanici baskasini sikayet edebilir" do
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "cc-rep", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "Hedef", provider: "github", uid: "cc-t1", terms_accepted_at: Time.current)
    sign_in_via_github(reporter)

    assert_difference "Complaint.count", 1 do
      post complaints_path, params: { target_user_id: target.id, description: "kotu davranis" }
    end
    complaint = Complaint.last
    assert_equal reporter, complaint.reported_by
    assert_equal target, complaint.target_user
  end

  test "kullanici kendini sikayet edemez" do
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "cc-rep2", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(reporter)

    assert_no_difference "Complaint.count" do
      post complaints_path, params: { target_user_id: reporter.id, description: "kendim" }
    end
    assert_redirected_to root_path
  end

  test "target_username ile sikayet edilebilir (case-insensitive)" do
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "cc-rep3", role: "member", terms_accepted_at: Time.current)
    target = User.create!(name: "HedefKisi", provider: "github", uid: "cc-t3", terms_accepted_at: Time.current)
    sign_in_via_github(reporter)

    assert_difference "Complaint.count", 1 do
      post complaints_path, params: { target_username: "hedefkisi", description: "isimle sikayet" }
    end
    assert_equal target, Complaint.last.target_user
  end

  test "bulunamayan target_username net hata dondurur" do
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "cc-rep4", role: "member", terms_accepted_at: Time.current)
    sign_in_via_github(reporter)

    assert_no_difference "Complaint.count" do
      post complaints_path, params: { target_username: "OlmayanKisi", description: "test" }
    end
    assert_redirected_to root_path
    assert_match(/bulunamadı/, flash[:alert])
  end

  test "index sadece kullanicinin actigi sikayetleri listeler" do
    reporter = User.create!(name: "Sikayetci", provider: "github", uid: "cc-rep5", role: "member", terms_accepted_at: Time.current)
    other = User.create!(name: "Baskasi", provider: "github", uid: "cc-oth5", terms_accepted_at: Time.current)
    target = User.create!(name: "HedefUniq", provider: "github", uid: "cc-t5", terms_accepted_at: Time.current)
    Complaint.create!(reported_by: reporter, target_user: target, description: "benimsikayetim-uniq")
    Complaint.create!(reported_by: other, target_user: target, description: "baskasininsikayeti-uniq")
    sign_in_via_github(reporter)

    get complaints_path
    assert_response :success
    assert_match(/benimsikayetim-uniq/, response.body)
    assert_no_match(/baskasininsikayeti-uniq/, response.body)
  end

  test "giris yapmamis kullanici index goremez" do
    get complaints_path
    assert_redirected_to root_path
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
