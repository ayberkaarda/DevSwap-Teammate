require "test_helper"

class UserEmbeddingBuilderTest < ActiveSupport::TestCase
  # Iki vektor arasindaki cosine benzerligi (her ikisi de L2-normalize edildigi
  # icin dot product yeterli, ama guvenli olmasi acisindan tam formulu yaziyoruz).
  def cosine(a, b)
    dot = a.each_index.sum { |i| a[i] * b[i] }
    norm_a = Math.sqrt(a.sum { |v| v * v })
    norm_b = Math.sqrt(b.sum { |v| v * v })
    return 0.0 if norm_a.zero? || norm_b.zero?

    dot / (norm_a * norm_b)
  end

  def user_with_skill(uid, skill, direction: "teaching", weight: 1.0)
    user = User.create!(name: "Test", provider: "github", uid: uid, terms_accepted_at: Time.current)
    user.user_skills.create!(skill: skill, source: "manual", weight: weight, direction: direction)
    user
  end

  # --- Degismeyecek: MD5-bucket determinizmi ve normalizasyon.
  # 6.2'de UserEmbeddingBuilder teach/learn'e bolundu, bu davranis ayni kaldi. ---

  test "ayni skill adi her zaman ayni bucket'a duser" do
    user = User.create!(name: "Test", provider: "github", uid: "det-1", terms_accepted_at: Time.current)
    skill = Skill.create!(name: "Ruby", category: "language")
    user.user_skills.create!(skill: skill, source: "manual", weight: 1.0, direction: "teaching")

    vector_a = UserEmbeddingBuilder.call(user, role: "teaching")
    vector_b = UserEmbeddingBuilder.call(user, role: "teaching")

    assert_equal vector_a, vector_b
  end

  test "vektor normalize edilir (norm ~= 1)" do
    user = User.create!(name: "Test", provider: "github", uid: "det-2", terms_accepted_at: Time.current)
    skill = Skill.create!(name: "Rust", category: "language")
    user.user_skills.create!(skill: skill, source: "manual", weight: 3.0, direction: "teaching")

    vector = UserEmbeddingBuilder.call(user, role: "teaching")

    norm = Math.sqrt(vector.sum { |v| v * v })

    assert_in_delta 1.0, norm, 0.0001
  end

  test "skill'i olmayan kullanici icin sifir vektor doner" do
    user = User.create!(name: "Test", provider: "github", uid: "det-3", terms_accepted_at: Time.current)

    vector = UserEmbeddingBuilder.call(user, role: "teaching")

    assert_equal Array.new(UserEmbeddingBuilder::DIMENSIONS, 0.0), vector
  end

  # --- 6.2 sonrasi davranis: teach ve learn skilleri artik ayri vektorlere gidiyor. ---

  test "teach ve learn skilleri ayri vektorlere gider, birbirine karismaz" do
    user = User.create!(name: "Test", provider: "github", uid: "det-4", terms_accepted_at: Time.current)
    teach_skill = Skill.create!(name: "Elixir", category: "language")
    learn_skill = Skill.create!(name: "Go", category: "language")
    user.user_skills.create!(skill: teach_skill, source: "manual", weight: 1.0, direction: "teaching")
    user.user_skills.create!(skill: learn_skill, source: "manual", weight: 1.0, direction: "learning")

    teach_vector = UserEmbeddingBuilder.call(user, role: "teaching")
    learn_vector = UserEmbeddingBuilder.call(user, role: "learning")

    teach_buckets = teach_vector.each_index.select { |i| teach_vector[i] != 0.0 }
    learn_buckets = learn_vector.each_index.select { |i| learn_vector[i] != 0.0 }

    # Iki bilesenli sema: kategorili her skill kategori + kimlik olmak uzere iki
    # boyuta katki verir. Teach ve learn skilleri ayni "language" kategorisinde
    # oldugu icin kategori boyutunu paylasabilirler; kimlik boyutlari ise farkli.
    # Onemli olan: teach vektoru sadece teach skillini, learn vektoru sadece learn
    # skillini icermeli — birbirine karismamali.
    assert_equal 2, teach_buckets.size
    assert_equal 2, learn_buckets.size
    assert_not_equal teach_buckets, learn_buckets
  end

  test "gecersiz role ile cagrilirsa hata verir" do
    user = User.create!(name: "Test", provider: "github", uid: "det-5", terms_accepted_at: Time.current)

    assert_raises(ArgumentError) { UserEmbeddingBuilder.call(user, role: "invalid") }
  end

  # --- Yeni davranis: kategori-ortak bileseni sayesinde farkli isimli ama ayni
  # kategorideki skill'ler artik sifirdan buyuk bir taban benzerlik kazaniyor. ---

  test "ayni kategorideki farkli iki skill icin cosine benzerligi 0'dan belirgin buyuk" do
    rails = Skill.create!(name: "Ruby on Rails", category: "backend_framework")
    django = Skill.create!(name: "Django", category: "backend_framework")

    user_a = user_with_skill("cat-same-a", rails)
    user_b = user_with_skill("cat-same-b", django)

    vector_a = UserEmbeddingBuilder.call(user_a, role: "teaching")
    vector_b = UserEmbeddingBuilder.call(user_b, role: "teaching")

    sim = cosine(vector_a, vector_b)
    assert sim > 0.1, "ayni kategori icin cosine > 0.1 bekleniyordu, gelen: #{sim}"
  end

  test "farkli kategorilerdeki iki skill neredeyse dik kalir (cosine ~ 0)" do
    ruby = Skill.create!(name: "Ruby", category: "language")
    postgres = Skill.create!(name: "PostgreSQL", category: "database")

    user_a = user_with_skill("cat-diff-a", ruby)
    user_b = user_with_skill("cat-diff-b", postgres)

    vector_a = UserEmbeddingBuilder.call(user_a, role: "teaching")
    vector_b = UserEmbeddingBuilder.call(user_b, role: "teaching")

    sim = cosine(vector_a, vector_b)
    assert sim < 0.1, "farkli kategori icin cosine < 0.1 bekleniyordu, gelen: #{sim}"
  end

  test "ayni kategorideki benzerlik, farkli kategorideki benzerlikten yuksek" do
    rails = Skill.create!(name: "Ruby on Rails", category: "backend_framework")
    django = Skill.create!(name: "Django", category: "backend_framework")
    postgres = Skill.create!(name: "PostgreSQL", category: "database")

    same_a = UserEmbeddingBuilder.call(user_with_skill("rank-a", rails), role: "teaching")
    same_b = UserEmbeddingBuilder.call(user_with_skill("rank-b", django), role: "teaching")
    diff_b = UserEmbeddingBuilder.call(user_with_skill("rank-c", postgres), role: "teaching")

    assert cosine(same_a, same_b) > cosine(same_a, diff_b)
  end

  test "SkillAlias uzerinden erisilen skill, kanonik isimle ayni vektoru uretir" do
    canonical = Skill.create!(name: "Node.js", category: "backend_framework")
    SkillAlias.create!(alias_name: "nodejs", skill: canonical)
    # Ayni kavramin alias'a cozumlenen bir varyanti (duplike Skill kaydi).
    variant = Skill.create!(name: "NodeJS", category: "backend_framework")

    canonical_vector = UserEmbeddingBuilder.call(user_with_skill("alias-canon", canonical), role: "teaching")
    variant_vector = UserEmbeddingBuilder.call(user_with_skill("alias-variant", variant), role: "teaching")

    # Kimlik bileseni alias uzerinden kanonik ada indirgendigi ve kategori ayni
    # oldugu icin iki vektor birebir ayni olmali.
    assert_in_delta 1.0, cosine(canonical_vector, variant_vector), 0.0001
    assert_equal canonical_vector, variant_vector
  end

  test "kategorisi olmayan skill eski saf-kimlik davranisina geri doner (tek bucket)" do
    skill = Skill.create!(name: "SomeObscureTool", category: nil)
    user = user_with_skill("no-cat", skill)

    vector = UserEmbeddingBuilder.call(user, role: "teaching")
    buckets = vector.each_index.select { |i| vector[i] != 0.0 }

    assert_equal 1, buckets.size
    assert_in_delta 1.0, Math.sqrt(vector.sum { |v| v * v }), 0.0001
  end
end
