require "test_helper"

class MatchCalculationJobTest < ActiveJob::TestCase
  def setup
    @author = User.create!(name: "Yazar", provider: "github", uid: "mcj-author", terms_accepted_at: Time.current)
    @teacher = User.create!(name: "Ogretmen", provider: "github", uid: "mcj-teacher", terms_accepted_at: Time.current)
    @learner = User.create!(name: "Ogrenci", provider: "github", uid: "mcj-learner", terms_accepted_at: Time.current)
    @stranger = User.create!(name: "Alakasiz", provider: "github", uid: "mcj-stranger", terms_accepted_at: Time.current)

    @rust = Skill.create!(name: "Rust", category: "language")
    @python = Skill.create!(name: "Python", category: "language")

    @teacher.user_skills.create!(skill: @rust, source: "manual", direction: "teaching")
    @learner.user_skills.create!(skill: @rust, source: "manual", direction: "learning")
    @stranger.user_skills.create!(skill: @python, source: "manual", direction: "teaching")
  end

  test "eslesen skile sahip teaching ve learning kullanicilara bildirim gonderir" do
    post = create_post("Rust ile bir proje yapiyorum, yardim lazim.")

    MatchCalculationJob.perform_now(post)

    assert PostNotification.exists?(post: post, user: @teacher), "teaching kullaniciya bildirim gitmeli"
    assert PostNotification.exists?(post: post, user: @learner), "learning kullaniciya bildirim gitmeli"
  end

  test "post sahibine bildirim gitmez" do
    @author.user_skills.create!(skill: @rust, source: "manual", direction: "teaching")
    post = create_post("Rust ogreniyorum.")

    MatchCalculationJob.perform_now(post)

    assert_not PostNotification.exists?(post: post, user: @author), "post sahibine bildirim gitmemeli"
  end

  test "alakasiz skile sahip kullaniciya bildirim gitmez" do
    post = create_post("Rust harika bir dil.")

    MatchCalculationJob.perform_now(post)

    assert_not PostNotification.exists?(post: post, user: @stranger), "sadece Python bilen kullaniciya gitmemeli"
  end

  test "kisa skill adi kelime icinde yanlislikla eslesmez (word boundary)" do
    go = Skill.create!(name: "Go", category: "language")
    go_dev = User.create!(name: "Go Dev", provider: "github", uid: "mcj-godev", terms_accepted_at: Time.current)
    go_dev.user_skills.create!(skill: go, source: "manual", direction: "teaching")

    post = create_post("Ben markete going yapiyorum, gitmem lazim.")

    MatchCalculationJob.perform_now(post)

    assert_not PostNotification.exists?(post: post, user: go_dev),
               "'Go', 'going' kelimesi icinde eslesmemis olmali"
  end

  test "eslesme yoksa hic bildirim olusturmaz" do
    post = create_post("Bugun hava cok guzel.")

    assert_no_difference "PostNotification.count" do
      MatchCalculationJob.perform_now(post)
    end
  end

  test "tekrar calisinca duplicate bildirim olusturmaz" do
    post = create_post("Rust super.")

    MatchCalculationJob.perform_now(post)
    count_after_first = PostNotification.where(post: post).count

    MatchCalculationJob.perform_now(post)
    count_after_second = PostNotification.where(post: post).count

    assert_equal count_after_first, count_after_second, "tekrar calisma duplicate uretmemeli"
  end

  private

  def create_post(content)
    # after_create_commit callback'inin job'u ikinci kez enqueue etmemesi icin
    # callback'i bu testte tetiklemeden dogrudan olusturuyoruz.
    Post.create!(user: @author, content: content, title: "Test")
  end
end
