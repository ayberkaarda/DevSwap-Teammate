require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "index is accessible without login" do
    get posts_path
    assert_response :success
    assert_match posts(:one).content, response.body
  end

  test "show is accessible without login" do
    get post_path(posts(:one))
    assert_response :success
  end

  test "by_tag is accessible without login and shows only tagged posts" do
    posts(:one).skills << skills(:one)

    get tag_posts_path(tag: skills(:one).name)

    assert_response :success
    assert_match post_path(posts(:one)), response.body
    assert_no_match post_path(posts(:two)), response.body
  end

  test "create requires login" do
    assert_no_difference("Post.count") do
      post posts_path, params: { content: "denenmis" }
    end
    assert_redirected_to root_path
  end

  test "create assigns skills from skill_ids when logged in" do
    viewer = User.create!(name: "Yazar", provider: "github", uid: "posts-create-1", terms_accepted_at: Time.current)
    sign_in_via_github(viewer)

    assert_difference("Post.count", 1) do
      post posts_path, params: { content: "yeni durum raporu", title: "Başlık", skill_ids: [ skills(:one).id ] }
    end

    created = Post.order(:created_at).last
    assert_equal [ skills(:one) ], created.skills
    assert_redirected_to root_path
  end

  test "index pagination returns first page posts and hides second page posts" do
    author = users(:one)
    # created_at artan sirayla 25 yeni post: i=25 en yeni, i=1 en eski.
    25.times do |n|
      i = n + 1
      Post.create!(content: "PAGE-MARK-#{i}", user: author, created_at: Time.current + i.seconds)
    end

    # Sayfa 1 (varsayilan): en yeni 20 post -> i=25..6 gorunur, i=5 gorunmez.
    get posts_path
    assert_response :success
    assert_match "PAGE-MARK-25", response.body
    assert_match "PAGE-MARK-6", response.body
    assert_no_match(/PAGE-MARK-5\b/, response.body)

    # Sayfa 2: offset 20 -> i=5 gorunur, i=6 artik gorunmez.
    get posts_path, params: { page: 2 }
    assert_response :success
    assert_match(/PAGE-MARK-5\b/, response.body)
    assert_no_match(/PAGE-MARK-6\b/, response.body)
  end

  test "index paginates over turbo stream and appends next page posts" do
    author = users(:one)
    25.times do |n|
      i = n + 1
      Post.create!(content: "TS-MARK-#{i}", user: author, created_at: Time.current + i.seconds)
    end

    get posts_path, params: { page: 2 }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "turbo-stream", response.body
    assert_match(/TS-MARK-5\b/, response.body)
  end

  test "trending tags are ordered by real post count descending" do
    author = users(:one)
    ruby = skills(:one)   # Ruby
    react = skills(:two)  # React

    # Ruby 3 post, React 1 post -> Ruby, React'ten once gelmeli.
    3.times do |n|
      p = Post.create!(content: "trend-ruby-#{n}", user: author)
      p.skills << ruby
    end
    react_post = Post.create!(content: "trend-react-0", user: author)
    react_post.skills << react

    get posts_path
    assert_response :success

    # Trend etiketler container'i icinde Ruby, React'ten once listelenmeli.
    trending_section = response.body.split("TREND ETİKETLER").last
    ruby_pos = trending_section.index("##{ruby.name}")
    react_pos = trending_section.index("##{react.name}")

    assert_not_nil ruby_pos, "Ruby trend etiketlerde gorunmeli"
    assert_not_nil react_pos, "React trend etiketlerde gorunmeli"
    assert ruby_pos < react_pos, "3 postlu Ruby, 1 postlu React'ten once siralanmali"
  end

  test "tag_search redirects hash query to tag feed" do
    get posts_path, params: { tag_search: "##{skills(:two).name}" }
    assert_redirected_to tag_posts_path(tag: skills(:two).name)
  end

  test "tag_search with unknown tag redirects back to feed" do
    get posts_path, params: { tag_search: "#nonexistent-tag-xyz" }
    assert_redirected_to posts_path
  end

  test "staff post silince silme loglanir (post_deleted)" do
    author = User.create!(name: "PDauthor", provider: "github", uid: "pd-author", terms_accepted_at: Time.current)
    admin = User.create!(name: "PDadmin", provider: "github", uid: "pd-admin", role: "admin", terms_accepted_at: Time.current)
    p = Post.create!(content: "silinecek post", user: author)
    sign_in_via_github(admin)

    assert_difference "Post.count", -1 do
      assert_difference "ActivityLog.count", 1 do
        delete destroy_post_path(p)
      end
    end
    assert_equal "post_deleted", ActivityLog.recent.first.action_type
  end

  test "q ile Users: yazar adina gore filtreler" do
    ada = users(:one)   # Ada Lovelace
    alan = users(:two)  # Alan Turing
    Post.create!(content: "SEARCH-ADA-POST", user: ada)
    Post.create!(content: "SEARCH-ALAN-POST", user: alan)

    get posts_path, params: { q: "Users:ada" }
    assert_response :success
    assert_match "SEARCH-ADA-POST", response.body
    assert_no_match(/SEARCH-ALAN-POST/, response.body)
  end

  test "q ile tag: etikete gore filtreler" do
    author = users(:one)
    ruby = skills(:one)
    tagged = Post.create!(content: "SEARCH-RUBY-TAGGED", user: author)
    tagged.skills << ruby
    Post.create!(content: "SEARCH-UNTAGGED", user: author)

    get posts_path, params: { q: "tag:#{ruby.name}" }
    assert_response :success
    assert_match "SEARCH-RUBY-TAGGED", response.body
    assert_no_match(/SEARCH-UNTAGGED/, response.body)
  end

  test "q serbest metinle icerik icinde arar" do
    author = users(:one)
    Post.create!(content: "SEARCH-FREETEXT-NEEDLE burada", user: author)
    Post.create!(content: "SEARCH-OTHER-CONTENT", user: author)

    get posts_path, params: { q: "needle" }
    assert_response :success
    assert_match "SEARCH-FREETEXT-NEEDLE", response.body
    assert_no_match(/SEARCH-OTHER-CONTENT/, response.body)
  end

  test "sort=most_liked en cok begenilen postu once siralar" do
    author = users(:one)
    liker1 = User.create!(name: "liker1", provider: "github", uid: "sort-l1", terms_accepted_at: Time.current)
    liker2 = User.create!(name: "liker2", provider: "github", uid: "sort-l2", terms_accepted_at: Time.current)
    popular = Post.create!(content: "SORT-POPULAR", user: author, created_at: 2.hours.ago)
    quiet   = Post.create!(content: "SORT-QUIET", user: author, created_at: 1.hour.ago)
    Like.create!(user: liker1, likeable: popular)
    Like.create!(user: liker2, likeable: popular)

    get posts_path, params: { sort: "most_liked" }
    assert_response :success
    assert response.body.index("SORT-POPULAR") < response.body.index("SORT-QUIET"),
           "En cok begenilen post digerinden once gelmeli"
  end

  test "sort=most_reposted en cok yeniden paylasilan postu once siralar" do
    author = users(:one)
    r1 = User.create!(name: "rep1", provider: "github", uid: "sort-r1", terms_accepted_at: Time.current)
    popular = Post.create!(content: "SORT-REP-POPULAR", user: author, created_at: 2.hours.ago)
    quiet   = Post.create!(content: "SORT-REP-QUIET", user: author, created_at: 1.hour.ago)
    Repost.create!(user: r1, post: popular)

    get posts_path, params: { sort: "most_reposted" }
    assert_response :success
    assert response.body.index("SORT-REP-POPULAR") < response.body.index("SORT-REP-QUIET")
  end

  test "range=today yalnizca bugunun postlarini gosterir" do
    author = users(:one)
    Post.create!(content: "RANGE-TODAY-POST", user: author, created_at: Time.current)
    Post.create!(content: "RANGE-OLD-POST", user: author, created_at: 3.days.ago)

    get posts_path, params: { range: "today" }
    assert_response :success
    assert_match "RANGE-TODAY-POST", response.body
    assert_no_match(/RANGE-OLD-POST/, response.body)
  end

  test "gecersiz sort/range degerleri guvenli varsayilana duser" do
    get posts_path, params: { sort: "; DROP TABLE", range: "haha" }
    assert_response :success
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
