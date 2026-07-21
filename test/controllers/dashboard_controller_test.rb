require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "vektoru olmayan kullanici icin tum kullanicilari listeler (fallback)" do
    viewer = User.create!(name: "Izleyici", provider: "github", uid: "dash-viewer-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get root_path

    assert_response :success
    assert_match users(:two).name, response.body
  end

  test "q parametresi varsa LIKE aramasi calisir" do
    viewer = User.create!(name: "Izleyici", provider: "github", uid: "dash-viewer-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get root_path(q: "React")

    assert_response :success
    assert_match users(:two).name, response.body
  end

  test "coklu terim aramasinda her iki terimi de karsilayan kullanici tek terimi karsilayandan once gelir" do
    viewer = User.create!(name: "Izleyici", provider: "github", uid: "dash-multi-1", terms_accepted_at: Time.current)
    both = User.create!(name: "Ikisini Bilen", provider: "github", uid: "dash-multi-2", terms_accepted_at: Time.current)
    only_one = User.create!(name: "Birini Bilen", provider: "github", uid: "dash-multi-3", terms_accepted_at: Time.current)

    react = Skill.create!(name: "React", category: "framework")
    laravel = Skill.create!(name: "Laravel", category: "framework")

    both.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "teaching")
    both.user_skills.create!(skill: laravel, source: "manual", weight: 1.0, direction: "teaching")
    only_one.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "teaching")

    sign_in_via_github(viewer)

    get root_path(q: "react laravel")

    assert_response :success
    both_index = response.body.index(both.name)
    only_one_index = response.body.index(only_one.name)

    assert both_index.present?
    assert only_one_index.present?
    assert both_index < only_one_index, "iki terimi de karsilayan kullanici daha once listelenmeli"
  end

  test "vektoru olan kullanici icin capraz eslesme dogru adayi dondurur" do
    teacher = User.create!(name: "Rust Ogretmeni", provider: "github", uid: "dash-1", terms_accepted_at: Time.current)
    learner = User.create!(name: "Rust Ogrencisi", provider: "github", uid: "dash-2", terms_accepted_at: Time.current)
    unrelated = User.create!(name: "Ilgisiz Kullanici", provider: "github", uid: "dash-3", terms_accepted_at: Time.current)

    rust = Skill.create!(name: "Rust", category: "language")
    cobol = Skill.create!(name: "Cobol", category: "language")

    teacher.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "teaching")
    learner.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "learning")
    unrelated.user_skills.create!(skill: cobol, source: "manual", weight: 1.0, direction: "teaching")

    [ teacher, learner, unrelated ].each do |user|
      GenerateUserEmbeddingJob.new.perform(user.id, force: true)
    end

    sign_in_via_github(teacher)

    get root_path

    assert_response :success
    assert_match learner.name, response.body
    assert_no_match(/#{Regexp.escape(unrelated.name)}/, response.body)
  end

  test "github kaynakli skill dashboard'da gorunur" do
    viewer = User.create!(name: "Tarama Kullanicisi", provider: "github", uid: "dash-scan-1", terms_accepted_at: Time.current)
    skill = Skill.create!(name: "Elixir", category: "language")
    viewer.user_skills.create!(skill: skill, source: "github", weight: 0.42, direction: "teaching")

    sign_in_via_github(viewer)

    get root_path

    assert_response :success
    assert_match "Elixir", response.body
  end

  test "manuel eklenen skill github tarama kartinda gorunmez" do
    viewer = User.create!(name: "Manuel Kullanicisi", provider: "github", uid: "dash-scan-2", terms_accepted_at: Time.current)
    skill = Skill.create!(name: "Haskell", category: "language")
    viewer.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    sign_in_via_github(viewer)

    get root_path

    assert_response :success
    assert_no_match(/GITHUB_SCAN\.detected/, response.body)
  end

  test "q parametresi # ile basliyorsa etiket sayfasina yonlendirir" do
    viewer = User.create!(name: "Izleyici", provider: "github", uid: "dash-tag-1", terms_accepted_at: Time.current)
    react = Skill.create!(name: "React", category: "framework")
    sign_in_via_github(viewer)

    get root_path(q: "#react")

    assert_redirected_to tag_posts_path(tag: react.name)
  end

  test "q parametresi bilinmeyen bir etiketle basliyorsa ana sayfaya yonlendirir" do
    viewer = User.create!(name: "Izleyici", provider: "github", uid: "dash-tag-2", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    get root_path(q: "#bilinmeyenetiket")

    assert_redirected_to root_path
  end

  # --- Faz 32d: "Bağlantı Kur" vs "Sohbete Git" etiket mantigi ---

  test "DM yokken aday karti 'Bağlantı Kur' etiketini gosterir" do
    viewer = User.create!(name: "Etiket Izleyici", provider: "github", uid: "label-1", terms_accepted_at: Time.current)
    candidate = User.create!(name: "Etiket Aday Kisi", provider: "github", uid: "label-2", terms_accepted_at: Time.current)
    react = Skill.create!(name: "React", category: "framework")
    candidate.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "teaching")

    sign_in_via_github(viewer)

    get root_path(q: "React")

    assert_response :success
    assert_match candidate.name, response.body
    assert_match "Bağlantı Kur", response.body
    assert_no_match "Sohbete Git", response.body
  end

  test "DM zaten varken aday karti 'Sohbete Git' etiketini gosterir" do
    viewer = User.create!(name: "Etiket Izleyici 2", provider: "github", uid: "label-3", terms_accepted_at: Time.current)
    candidate = User.create!(name: "Etiket Bagli Kisi", provider: "github", uid: "label-4", terms_accepted_at: Time.current)
    react = Skill.create!(name: "React", category: "framework")
    candidate.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "teaching")
    ChatRoom.find_or_create_dm_between(viewer, candidate)

    sign_in_via_github(viewer)

    get root_path(q: "React")

    assert_response :success
    assert_match candidate.name, response.body
    assert_match "Sohbete Git", response.body
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
