require "test_helper"

class UserSkillsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "skill_ids ile coklu secim tum yetenekleri learning olarak ekler" do
    user = User.create!(name: "Coklu Secim", provider: "github", uid: "us-1", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    rust = Skill.create!(name: "Rust", category: "language")
    python = Skill.create!(name: "Python", category: "language")

    assert_enqueued_with(job: GenerateUserEmbeddingJob) do
      post user_skills_path, params: { skill_ids: [ rust.id, python.id ], direction: "learning" }
    end

    assert_redirected_to root_path

    user_skills = user.user_skills.reload
    assert_equal 2, user_skills.count
    assert user_skills.all? { |us| us.direction == "learning" }
    assert_equal [ rust.id, python.id ].sort, user_skills.pluck(:skill_id).sort
    assert user_skills.all? { |us| us.source == "manual" }
  end

  test "skill_ids listesinde zaten sahip olunan yetenek tekrar eklenmez" do
    user = User.create!(name: "Tekrarsiz Secim", provider: "github", uid: "us-2", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    rust = Skill.create!(name: "Rust", category: "language")
    python = Skill.create!(name: "Python", category: "language")

    user.user_skills.create!(skill: rust, source: "manual", weight: nil, direction: "learning")

    post user_skills_path, params: { skill_ids: [ rust.id, python.id ], direction: "learning" }

    assert_redirected_to root_path

    user_skills = user.user_skills.reload
    assert_equal 2, user_skills.count
    assert_equal [ rust.id, python.id ].sort, user_skills.pluck(:skill_id).sort
  end

  test "skill_ids istegi GenerateUserEmbeddingJob'u kuyruga ekler" do
    user = User.create!(name: "Kuyruk Kontrol", provider: "github", uid: "us-3", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    skill = Skill.create!(name: "Go", category: "language")

    assert_enqueued_with(job: GenerateUserEmbeddingJob) do
      post user_skills_path, params: { skill_ids: [ skill.id ], direction: "learning" }
    end
  end

  test "skill_id (tekil dropdown) yolu hala calisiyor" do
    user = User.create!(name: "Tekil Secim", provider: "github", uid: "us-4", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    skill = Skill.create!(name: "Elixir", category: "language")

    assert_enqueued_with(job: GenerateUserEmbeddingJob) do
      post user_skills_path, params: { skill_id: skill.id, direction: "teaching" }
    end

    assert_redirected_to root_path

    user_skills = user.user_skills.reload
    assert_equal 1, user_skills.count
    assert_equal skill.id, user_skills.first.skill_id
    assert_equal "teaching", user_skills.first.direction
  end

  test "skill_name (serbest metin) eslesmeyen metinle YENI Skill OLUSTURMAZ" do
    # Regresyon: Onceden SkillResolver.call cagrisi kanonik havuzu baypas ederek
    # her serbest metin icin yeni bir Skill kaydi olusturuyordu. Artik olmamali.
    user = User.create!(name: "Serbest Metin", provider: "github", uid: "us-5", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    assert_no_difference [ "Skill.count", "SkillAlias.count" ] do
      assert_enqueued_with(job: GenerateUserEmbeddingJob) do
        post user_skills_path, params: { skill_name: "kesinlikle-var-olmayan-yetenek", direction: "teaching" }
      end
    end

    assert_redirected_to root_path

    # Eslesme olmadigi icin sessizce no-op: kullaniciya user_skill de eklenmez.
    assert_equal 0, user.user_skills.reload.count
  end

  test "skill_name mevcut bir alias ile kanonik Skill'e baglar, yeni kayit olusturmaz" do
    user = User.create!(name: "Alias Eslesme", provider: "github", uid: "us-11", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    node = Skill.create!(name: "Node.js", category: "language")
    SkillAlias.create!(alias_name: "nodejs", skill: node)

    assert_no_difference "Skill.count" do
      post user_skills_path, params: { skill_name: "NodeJS", direction: "teaching" }
    end

    assert_redirected_to root_path

    user_skills = user.user_skills.reload
    assert_equal 1, user_skills.count
    assert_equal node.id, user_skills.first.skill_id
    assert_equal "teaching", user_skills.first.direction
  end

  test "skill_name farkli buyuk-kucuk harf/bosluk ile mevcut Skill'e baglar, yeni kayit olusturmaz" do
    user = User.create!(name: "Case Insensitive", provider: "github", uid: "us-12", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    # skills.yml fixture'indan "Ruby" kaydini kullan.
    existing = skills(:one)

    assert_no_difference "Skill.count" do
      post user_skills_path, params: { skill_name: "  ruby ", direction: "learning" }
    end

    assert_redirected_to root_path

    user_skills = user.user_skills.reload
    assert_equal 1, user_skills.count
    assert_equal existing.id, user_skills.first.skill_id
    assert_equal "learning", user_skills.first.direction
  end

  test "PATCH gecerli proficiency_level, note ve evidence_url ile user_skill'i gunceller" do
    user = User.create!(name: "Guncelleme Testi", provider: "github", uid: "us-6", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    skill = Skill.create!(name: "Kotlin", category: "language")
    user_skill = user.user_skills.create!(skill: skill, source: "manual", direction: "teaching")

    patch user_skill_path(user_skill), params: {
      user_skill: { proficiency_level: "advanced", note: "3 yildir kullaniyorum", evidence_url: "https://github.com/example" }
    }

    assert_redirected_to root_path

    user_skill.reload
    assert_equal "advanced", user_skill.proficiency_level
    assert_equal "3 yildir kullaniyorum", user_skill.note
    assert_equal "https://github.com/example", user_skill.evidence_url
  end

  test "PATCH gecersiz proficiency_level ile guncelleme basarisiz olur ve degistirmez" do
    user = User.create!(name: "Gecersiz Seviye", provider: "github", uid: "us-7", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    skill = Skill.create!(name: "Nim", category: "language")
    user_skill = user.user_skills.create!(skill: skill, source: "manual", direction: "teaching", proficiency_level: "beginner")

    patch user_skill_path(user_skill), params: { user_skill: { proficiency_level: "invalid_value" } }

    user_skill.reload
    assert_equal "beginner", user_skill.proficiency_level
  end

  test "PATCH gecersiz evidence_url (javascript:) ile guncelleme basarisiz olur" do
    user = User.create!(name: "Gecersiz Link", provider: "github", uid: "us-8", terms_accepted_at: Time.current)
    sign_in_via_github(user)

    skill = Skill.create!(name: "Zig", category: "language")
    user_skill = user.user_skills.create!(skill: skill, source: "manual", direction: "teaching")

    patch user_skill_path(user_skill), params: { user_skill: { evidence_url: "javascript:alert(1)" } }

    user_skill.reload
    assert_nil user_skill.evidence_url
  end

  test "PATCH baskasinin user_skill'ini guncellemeye calisinca not_found doner" do
    owner = User.create!(name: "Sahip", provider: "github", uid: "us-9", terms_accepted_at: Time.current)
    intruder = User.create!(name: "Yetkisiz", provider: "github", uid: "us-10", terms_accepted_at: Time.current)
    sign_in_via_github(intruder)

    skill = Skill.create!(name: "Crystal", category: "language")
    owner_user_skill = owner.user_skills.create!(skill: skill, source: "manual", direction: "teaching")

    patch user_skill_path(owner_user_skill), params: { user_skill: { proficiency_level: "expert" } }

    assert_response :not_found

    owner_user_skill.reload
    assert_nil owner_user_skill.proficiency_level
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
