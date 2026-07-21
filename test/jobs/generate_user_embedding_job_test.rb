require "test_helper"

class GenerateUserEmbeddingJobTest < ActiveJob::TestCase
  test "MIN_RECOMPUTE_INTERVAL icinde ise yeniden hesaplamayi atlar" do
    skill = Skill.create!(name: "Haskell", category: "language")

    user = User.create!(name: "T", provider: "github", uid: "job-1", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    record = UserSkillVector.create!(user: user, embedding_teach: Array.new(512, 0.0),
                                      embedding_learn: Array.new(512, 0.0),
                                      skill_distribution: {}, generated_at: 1.hour.ago)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert_equal record.generated_at.to_i, record.reload.generated_at.to_i
  end

  test "dagilim degisimi esik altindaysa atlar" do
    skill = Skill.create!(name: "Python", category: "language")

    user = User.create!(name: "T", provider: "github", uid: "job-2", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    distribution = { skill.id.to_s => 1.0 }
    record = UserSkillVector.create!(user: user, embedding_teach: Array.new(512, 0.0),
                                      embedding_learn: Array.new(512, 0.0),
                                      skill_distribution: distribution, generated_at: 2.days.ago)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert_equal record.generated_at.to_i, record.reload.generated_at.to_i
  end

  test "teach ve learn vektorlerinin ikisi de esik ustundeyse atlar" do
    teach_skill = Skill.create!(name: "Kotlin", category: "language")
    learn_skill = Skill.create!(name: "Swift", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-3", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: teach_skill, source: "manual", weight: 1.0, direction: "teaching")
    user.user_skills.create!(skill: learn_skill, source: "manual", weight: 1.0, direction: "learning")

    record = UserSkillVector.create!(user: user,
                                      embedding_teach: UserEmbeddingBuilder.call(user, role: "teaching"),
                                      embedding_learn: UserEmbeddingBuilder.call(user, role: "learning"),
                                      skill_distribution: {}, generated_at: 2.days.ago)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert_equal record.generated_at.to_i, record.reload.generated_at.to_i
  end

  test "sadece teach vektoru degistiyse learn ayni olsa bile gunceller" do
    teach_skill = Skill.create!(name: "Zig", category: "language")
    learn_skill = Skill.create!(name: "Nim", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-4", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: teach_skill, source: "manual", weight: 1.0, direction: "teaching")
    user.user_skills.create!(skill: learn_skill, source: "manual", weight: 1.0, direction: "learning")

    record = UserSkillVector.create!(user: user,
                                      embedding_teach: Array.new(512, 0.0),
                                      embedding_learn: UserEmbeddingBuilder.call(user, role: "learning"),
                                      skill_distribution: {}, generated_at: 2.days.ago)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert record.reload.generated_at > 1.minute.ago
  end

  test "hicbir koruma tutmuyorsa kaydi gunceller" do
    skill = Skill.create!(name: "Crystal", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-5", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    record = UserSkillVector.create!(user: user, embedding_teach: Array.new(512, 0.0),
                                      embedding_learn: Array.new(512, 0.0),
                                      skill_distribution: {}, generated_at: 2.days.ago)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert record.reload.generated_at > 1.minute.ago
  end

  test "force: true ise korumalari atlayip gunceller" do
    skill = Skill.create!(name: "Elm", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-6", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    vector = UserEmbeddingBuilder.call(user, role: "teaching")
    record = UserSkillVector.create!(user: user, embedding_teach: vector,
                                      embedding_learn: Array.new(512, 0.0),
                                      skill_distribution: { skill.id.to_s => 1.0 },
                                      generated_at: 1.minute.ago)

    GenerateUserEmbeddingJob.new.perform(user.id, force: true)

    assert record.reload.generated_at > 30.seconds.ago
  end

  test "kullanicinin son skill'i silinince mevcut embedding kaydi temizlenir" do
    skill = Skill.create!(name: "Ruby", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-7", terms_accepted_at: Time.current)
    user_skill = user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    record = UserSkillVector.create!(user: user, embedding_teach: Array.new(512, 0.1),
                                      embedding_learn: Array.new(512, 0.1),
                                      skill_distribution: { skill.id.to_s => 1.0 }, generated_at: 2.days.ago)

    user_skill.destroy

    GenerateUserEmbeddingJob.new.perform(user.id)

    record.reload
    assert_nil record.embedding_teach
    assert_nil record.embedding_learn
    assert_nil record.generated_at
    assert_equal({}, record.skill_distribution)
  end

  test "hic skill'i ve embedding kaydi olmayan kullanici icin yeni kayit olusturmaz" do
    user = User.create!(name: "T", provider: "github", uid: "job-8", terms_accepted_at: Time.current)

    GenerateUserEmbeddingJob.new.perform(user.id)

    assert_not UserSkillVector.where(user: user).exists?
  end

  test "bir rolde hic skill'i olmayan kullanici icin o rolun vektoru nil kaydedilir (regresyon)" do
    skill = Skill.create!(name: "Rust", category: "language")
    user = User.create!(name: "T", provider: "github", uid: "job-9", terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    GenerateUserEmbeddingJob.new.perform(user.id)

    record = UserSkillVector.find_by(user: user)
    assert_not record.embedding_teach.blank?
    # NaN regresyonu: sifir vektor degil, tam olarak nil olmali
    assert_nil record.embedding_learn
  end
end
