require "test_helper"

class MatchFinderTest < ActiveSupport::TestCase
  test "tek yonlu eslesmede skor, reciprocal false ve reason agirlikli skill sirasiyla doner" do
    teacher = User.create!(name: "Ogretmen", provider: "github", uid: "mf-1", terms_accepted_at: Time.current)
    learner = User.create!(name: "Ogrenci", provider: "github", uid: "mf-2", terms_accepted_at: Time.current)

    rust = Skill.create!(name: "Rust", category: "language")
    react = Skill.create!(name: "React", category: "framework")

    teacher.user_skills.create!(skill: rust, source: "manual", weight: 2.0, direction: "teaching")
    teacher.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "teaching")

    learner.user_skills.create!(skill: rust, source: "manual", weight: 2.0, direction: "learning")
    learner.user_skills.create!(skill: react, source: "manual", weight: 1.0, direction: "learning")

    [ teacher, learner ].each { |user| GenerateUserEmbeddingJob.new.perform(user.id, force: true) }

    results = MatchFinder.call(teacher)
    match = results.find { |c| c.id == learner.id }

    assert match.is_a?(MatchFinder::Match)
    assert match.score >= 0.0
    assert match.score <= 1.0
    assert_equal false, match.reciprocal
    assert_match(/Rust/, match.reason)
    assert_match(/\ARust( \+ React)? kesişimi\z/, match.reason)
  end

  test "karsilikli tam swap durumunda reciprocal true doner" do
    user_a = User.create!(name: "Kullanici A", provider: "github", uid: "mf-3", terms_accepted_at: Time.current)
    user_b = User.create!(name: "Kullanici B", provider: "github", uid: "mf-4", terms_accepted_at: Time.current)

    rust = Skill.create!(name: "Rust", category: "language")
    python = Skill.create!(name: "Python", category: "language")

    user_a.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "teaching")
    user_a.user_skills.create!(skill: python, source: "manual", weight: 1.0, direction: "learning")

    user_b.user_skills.create!(skill: python, source: "manual", weight: 1.0, direction: "teaching")
    user_b.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "learning")

    [ user_a, user_b ].each { |user| GenerateUserEmbeddingJob.new.perform(user.id, force: true) }

    results = MatchFinder.call(user_a)
    match = results.find { |c| c.id == user_b.id }

    assert match.is_a?(MatchFinder::Match)
    assert_equal true, match.reciprocal
  end

  test "ayni ham skora sahip adaylar arasinda average_rating yuksek olan once gelir" do
    viewer = User.create!(name: "Degerlendirici", provider: "github", uid: "mf-rating-1", terms_accepted_at: Time.current)
    high_rated = User.create!(name: "Yuksek Puanli", provider: "github", uid: "mf-rating-2", terms_accepted_at: Time.current, average_rating: 5.0)
    low_rated = User.create!(name: "Dusuk Puanli", provider: "github", uid: "mf-rating-3", terms_accepted_at: Time.current, average_rating: 1.0)

    rust = Skill.create!(name: "Rust", category: "language")

    viewer.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "learning")
    high_rated.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "teaching")
    low_rated.user_skills.create!(skill: rust, source: "manual", weight: 1.0, direction: "teaching")

    [ viewer, high_rated, low_rated ].each { |user| GenerateUserEmbeddingJob.new.perform(user.id, force: true) }

    results = MatchFinder.call(viewer)
    high_index = results.index { |c| c.id == high_rated.id }
    low_index = results.index { |c| c.id == low_rated.id }

    assert high_index.present?
    assert low_index.present?
    assert high_index < low_index, "average_rating yuksek olan aday once siralanmali"
  end

  test "vektoru olmayan kullanici icin duz User listesi doner (Match ile sarilmaz)" do
    viewer = User.create!(name: "Vektorsuz", provider: "github", uid: "mf-5", terms_accepted_at: Time.current)
    User.create!(name: "Diger", provider: "github", uid: "mf-6", terms_accepted_at: Time.current)

    results = MatchFinder.call(viewer)

    assert results.any?
    results.each do |candidate|
      assert_not candidate.is_a?(MatchFinder::Match)
      assert candidate.is_a?(User)
    end
  end

  # REGRESYON TESTI: Bu test artik YESIL geciyor. bucket_for (UserEmbeddingBuilder) zaten
  # downcase+strip normalizasyonu yapiyor, bu yuzden sadece buyuk/kucuk harf farki
  # (JavaScript/Javascript) eslesmeyi bozmuyor. Noktalama/bosluk farki iceren yazim varyantlari
  # ("Node.js" vs "NodeJS") ise downcase+strip sonrasi bile ("node.js" vs "nodejs") farkli MD5
  # bucket'a duser ve vektor eslesmesi bunlari birlestirmez; ancak MatchFinder#normalized_skill_name
  # / #match_normalized_skills PATCH'i, ID'leri farkli olsa da isimleri (bosluk/noktalama haric)
  # ayni olan var olan (legacy) duplicate Skill kayitlarini eslesme nedeninde (reason) normalize
  # ederek tolere ediyor - bu test o davranisi kanitliyor. Yazma anindaki kok nedeni (yeni duplicate
  # Skill kayitlarinin olusmasi) ise Faz 9'da eklenen SkillResolver (app/services/skill_resolver.rb)
  # + SkillAlias tablosu engelliyor: artik yeni yazimlar ayni kanonik Skill'e yonleniyor. Ikisi
  # birbirini tamamliyor - SkillResolver yeni duplicate olusumunu onler, bu patch var olan/legacy
  # duplicate'leri tolere eder.
  test "noktalama/bosluk farki nedeniyle Node.js ve NodeJS farkli skill olarak eslesmiyor" do
    teacher = User.create!(name: "Ogretmen Node", provider: "github", uid: "mf-7", terms_accepted_at: Time.current)
    learner = User.create!(name: "Ogrenci Node", provider: "github", uid: "mf-8", terms_accepted_at: Time.current)

    github_scanned_node = Skill.create!(name: "Node.js", category: "language")
    manual_variant_node = Skill.create!(name: "NodeJS", category: "language")

    assert_not_equal github_scanned_node.id, manual_variant_node.id

    teacher.user_skills.create!(skill: github_scanned_node, source: "github", weight: 1.0, direction: "teaching")
    learner.user_skills.create!(skill: manual_variant_node, source: "manual", weight: 1.0, direction: "learning")

    [ teacher, learner ].each { |user| GenerateUserEmbeddingJob.new.perform(user.id, force: true) }

    results = MatchFinder.call(teacher)
    match = results.find { |c| c.id == learner.id }

    assert match.present?, "Node.js ve NodeJS ayni kavram oldugu icin bu iki kullanici eslesmeliydi"
    assert match.reason.present?, "Node.js/NodeJS ayni kavram oldugu icin skill kesisimi/eslesme nedeni doldurulmaliydi, ama farkli Skill id'leri nedeniyle overlap bos donuyor"
  end
end
