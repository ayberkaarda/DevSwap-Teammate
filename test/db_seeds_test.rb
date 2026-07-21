require "test_helper"

class DbSeedsTest < ActiveSupport::TestCase
  test "db/seeds.rb is idempotent and safe by default (no SEED_RESET)" do
    # Guvenlik: SEED_RESET ayarli DEGIL, varsayilan (yikici olmayan) yolu test ediyoruz.
    assert_nil ENV["SEED_RESET"], "Bu test SEED_RESET set edilmeden calismali"

    seeds_path = Rails.root.join("db/seeds.rb")

    # Birinci calistirma: eksik demo kayitlarini ekler (fixture'lar zaten yuklu,
    # seeds.rb find_or_create_by! kullandigi icin onlara dokunmaz).
    load seeds_path
    user_count_after_first = User.count
    skill_count_after_first = Skill.count
    user_skill_count_after_first = UserSkill.count

    # Ikinci calistirma: hicbir hata firlatmamali (unique constraint / RecordInvalid yok)
    # ve duplicate kayit OLUSTURMAMALI.
    assert_nothing_raised do
      load seeds_path
    end

    assert_equal user_count_after_first, User.count,
      "Ikinci seed calistirmasi duplicate User olusturmamali"
    assert_equal skill_count_after_first, Skill.count,
      "Ikinci seed calistirmasi duplicate Skill olusturmamali"
    assert_equal user_skill_count_after_first, UserSkill.count,
      "Ikinci seed calistirmasi duplicate UserSkill olusturmamali"
  end
end
