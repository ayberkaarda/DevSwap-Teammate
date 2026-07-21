require "test_helper"

class WeeklyMatchDigestJobTest < ActiveJob::TestCase
  def setup
    @skill = Skill.create!(name: "Elixir", category: "language")

    # Skill'i olan kullanici: digest almali.
    @with_skills = User.create!(name: "Skilled", provider: "github", uid: "wmd-skilled", terms_accepted_at: Time.current)
    @with_skills.user_skills.create!(skill: @skill, source: "manual", direction: "teaching")

    # Skill'i olmayan kullanici: MatchFinder hic cagrilmamali, digest olmamali.
    @no_skills = User.create!(name: "Skilless", provider: "github", uid: "wmd-skilless", terms_accepted_at: Time.current)

    # Eslesme adaylari (skill guard'a takilmamalari icin skill vermiyoruz;
    # sadece MatchFinder stub'inin donebilecegi hedef kullanicilar).
    @candidates = 5.times.map do |i|
      User.create!(name: "Cand #{i}", provider: "github", uid: "wmd-cand-#{i}", terms_accepted_at: Time.current)
    end
  end

  # MatchFinder.call kendi singleton class'inda tanimli (inherited degil), bu yuzden
  # define_singleton_method/remove_method ile gecici stub yapmak, blok bitince metodu
  # tamamen siler (geri donecegi bir inherited metot yok - remove_method sadece
  # singleton class'taki entry'yi siler, altta baska bir tanim olmadigi icin
  # MatchFinder.call sonraki testler icin tamamen undefined kalir).
  #
  # (Not: Minitest 6'da Object#stub, ayri bir "minitest-mock" gem'ine tasindigi
  # ve Gemfile'da bulunmadigi icin kullanilamiyor.)
  #
  # Bunun yerine orijinal metodu (bir Method nesnesi olarak) saklayip blok
  # bitince ayni Method nesnesiyle geri tanimliyoruz. Boylece remove_method'a
  # hic gerek kalmiyor ve MatchFinder.call bu dosyadan sonra da calismaya devam ediyor.
  def stub_match_finder(results_by_uid, called_uids)
    original_call = MatchFinder.method(:call)

    MatchFinder.define_singleton_method(:call) do |user|
      called_uids << user.uid
      results_by_uid.fetch(user.uid, [])
    end

    yield
  ensure
    MatchFinder.define_singleton_method(:call, original_call)
  end

  test "skill'i olan ve en az 1 eslesmesi olan kullaniciya digest olusturur" do
    called = []
    results = { @with_skills.uid => [ @candidates[0], @candidates[1] ] }

    stub_match_finder(results, called) do
      WeeklyMatchDigestJob.perform_now
    end

    digest = MatchDigest.find_by(user: @with_skills)
    assert_not_nil digest, "skill'i olan kullaniciya digest olusmalı"
    assert_equal [ @candidates[0].id, @candidates[1].id ], digest.matched_user_ids
  end

  test "skill'i olmayan kullanici tamamen atlanir ve MatchFinder cagrilmaz" do
    called = []
    results = { @with_skills.uid => [ @candidates[0] ] }

    stub_match_finder(results, called) do
      WeeklyMatchDigestJob.perform_now
    end

    assert_nil MatchDigest.find_by(user: @no_skills), "skill'siz kullaniciya digest olusmamalı"
    assert_not_includes called, @no_skills.uid, "skill'siz kullanici icin MatchFinder cagrilmamalı"
    assert_includes called, @with_skills.uid, "skill'li kullanici icin MatchFinder cagrilmalı"
  end

  test "eslesme yoksa digest olusturmaz" do
    called = []
    results = { @with_skills.uid => [] }

    assert_no_difference "MatchDigest.count" do
      stub_match_finder(results, called) do
        WeeklyMatchDigestJob.perform_now
      end
    end
  end

  test "3'ten fazla aday olsa bile en fazla ilk 3'u kaydedilir" do
    called = []
    results = { @with_skills.uid => @candidates } # 5 aday

    stub_match_finder(results, called) do
      WeeklyMatchDigestJob.perform_now
    end

    digest = MatchDigest.find_by(user: @with_skills)
    assert_not_nil digest
    assert_equal 3, digest.matched_user_ids.size, "en fazla ilk 3 aday kaydedilmeli"
    assert_equal @candidates.first(3).map(&:id), digest.matched_user_ids
  end
end
