require "test_helper"

class PostSearchQueryTest < ActiveSupport::TestCase
  # --- Ayristirma (parsing) ---

  test "bos girdi hicbir filtre uretmez" do
    q = PostSearchQuery.new("")
    assert_empty q.usernames
    assert_empty q.tags
    assert_equal "", q.text
    assert_not q.present?
  end

  test "nil girdi guvenli sekilde ele alinir" do
    q = PostSearchQuery.new(nil)
    assert_not q.present?
  end

  test "Users: yazar adini cikarir (buyuk/kucuk harf duyarsiz anahtar)" do
    assert_equal [ "ayberk" ], PostSearchQuery.new("Users:ayberk").usernames
    assert_equal [ "ayberk" ], PostSearchQuery.new("user:ayberk").usernames
    assert_equal [ "ayberk" ], PostSearchQuery.new("USERS:ayberk").usernames
  end

  test "tag: virgulle ayrilmis birden fazla etiketi cikarir" do
    q = PostSearchQuery.new("tag:react,laravel,go")
    assert_equal %w[react laravel go], q.tags
  end

  test "birlesik sozdizimi: Users + tag + serbest metin" do
    q = PostSearchQuery.new("Users:ayberk tag:react,laravel turbo stream")
    assert_equal [ "ayberk" ], q.usernames
    assert_equal %w[react laravel], q.tags
    assert_equal "turbo stream", q.text
    assert q.present?
  end

  test "yalnizca serbest metin text olarak kalir" do
    q = PostSearchQuery.new("sadece serbest arama")
    assert_empty q.usernames
    assert_empty q.tags
    assert_equal "sadece serbest arama", q.text
  end

  # --- Uygulama (ActiveRecord scope) ---

  test "apply Users ile yazar adina gore filtreler" do
    author = users(:one) # Ada Lovelace
    other  = users(:two) # Alan Turing
    mine   = Post.create!(content: "ada postu", user: author)
    theirs = Post.create!(content: "alan postu", user: other)

    result = PostSearchQuery.new("Users:ada").apply(Post.all)
    assert_includes result, mine
    assert_not_includes result, theirs
  end

  test "apply tag ile etikete gore filtreler (ANY match)" do
    author = users(:one)
    ruby   = skills(:one)  # Ruby
    react  = skills(:two)  # React
    p_ruby = Post.create!(content: "ruby icerik", user: author)
    p_ruby.skills << ruby
    p_react = Post.create!(content: "react icerik", user: author)
    p_react.skills << react
    p_none = Post.create!(content: "etiketsiz", user: author)

    result = PostSearchQuery.new("tag:ruby,react").apply(Post.all)
    assert_includes result, p_ruby
    assert_includes result, p_react
    assert_not_includes result, p_none
  end

  test "apply serbest metinle icerik/baslik icinde arar" do
    author = users(:one)
    hit    = Post.create!(content: "burada TurboStream gecer", user: author)
    miss   = Post.create!(content: "alakasiz", user: author)

    result = PostSearchQuery.new("turbostream").apply(Post.all)
    assert_includes result, hit
    assert_not_includes result, miss
  end

  test "apply birlesik filtreleri AND olarak zincirler" do
    author = users(:one)   # Ada
    other  = users(:two)   # Alan
    ruby   = skills(:one)

    match = Post.create!(content: "eslesen ruby postu", user: author)
    match.skills << ruby

    wrong_author = Post.create!(content: "eslesen ruby postu", user: other)
    wrong_author.skills << ruby

    wrong_tag = Post.create!(content: "eslesen ruby postu", user: author)

    result = PostSearchQuery.new("Users:ada tag:ruby eslesen").apply(Post.all)
    assert_includes result, match
    assert_not_includes result, wrong_author
    assert_not_includes result, wrong_tag
  end
end
