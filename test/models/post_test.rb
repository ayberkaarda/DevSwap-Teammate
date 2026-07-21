require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "belongs to a user" do
    assert_equal users(:one), posts(:one).user
  end

  test "has many comments and destroys them on delete" do
    post = posts(:one)
    assert_difference("Comment.count", -1) do
      post.destroy
    end
  end

  test "enqueues MatchCalculationJob after create" do
    assert_enqueued_with(job: MatchCalculationJob) do
      Post.create!(title: "t", content: "c", user: users(:one))
    end
  end

  test "requires content" do
    post = Post.new(title: "t", content: "", user: users(:one))
    assert_not post.valid?
    assert_includes post.errors[:content], "can't be blank"
  end

  test "rejects content longer than 2000 characters" do
    post = Post.new(title: "t", content: "a" * 2001, user: users(:one))
    assert_not post.valid?
    assert_includes post.errors[:content], "is too long (maximum is 2000 characters)"
  end

  test "rejects title longer than 120 characters" do
    post = Post.new(title: "a" * 121, content: "c", user: users(:one))
    assert_not post.valid?
    assert_includes post.errors[:title], "is too long (maximum is 120 characters)"
  end

  test "can be tagged with skills via has_and_belongs_to_many" do
    post = posts(:one)
    post.skills << skills(:one)
    assert_includes post.reload.skills, skills(:one)
  end

  test "tagged_with scope returns only posts tagged with the given skill" do
    tagged = posts(:one)
    tagged.skills << skills(:one)

    assert_includes Post.tagged_with(skills(:one)), tagged
    assert_not_includes Post.tagged_with(skills(:one)), posts(:two)
  end
end
