require "test_helper"

class MatchDigestTest < ActiveSupport::TestCase
  def setup
    @owner = User.create!(name: "Digest Owner", provider: "github", uid: "md-owner", terms_accepted_at: Time.current)
    @a = User.create!(name: "Matched A", provider: "github", uid: "md-a", terms_accepted_at: Time.current)
    @b = User.create!(name: "Matched B", provider: "github", uid: "md-b", terms_accepted_at: Time.current)
    @c = User.create!(name: "Not Matched", provider: "github", uid: "md-c", terms_accepted_at: Time.current)
  end

  test "matched_user_ids jsonb'den Ruby Array olarak okunur" do
    digest = MatchDigest.create!(user: @owner, matched_user_ids: [ @a.id, @b.id ])
    digest.reload

    assert_equal [ @a.id, @b.id ], digest.matched_user_ids
    assert_kind_of Array, digest.matched_user_ids
  end

  test "matched_users kayitli id'lere karsilik gelen User'lari doner" do
    digest = MatchDigest.create!(user: @owner, matched_user_ids: [ @a.id, @b.id ])

    assert_equal [ @a.id, @b.id ].sort, digest.matched_users.pluck(:id).sort
    assert_not_includes digest.matched_users.pluck(:id), @c.id
  end

  test "unseen scope sadece seen_at nil olan kayitlari doner" do
    unseen = MatchDigest.create!(user: @owner, matched_user_ids: [ @a.id ])
    seen = MatchDigest.create!(user: @owner, matched_user_ids: [ @b.id ], seen_at: Time.current)

    assert_includes MatchDigest.unseen, unseen
    assert_not_includes MatchDigest.unseen, seen
  end

  test "active scope 14 gunden eski digest'leri dislar" do
    recent = MatchDigest.create!(user: @owner, matched_user_ids: [ @a.id ])
    old = MatchDigest.create!(user: @owner, matched_user_ids: [ @b.id ])
    old.update_column(:created_at, 15.days.ago)

    assert_includes MatchDigest.active, recent
    assert_not_includes MatchDigest.active, old
  end

  test "seen? seen_at doluysa true, bossa false doner" do
    unseen = MatchDigest.create!(user: @owner, matched_user_ids: [ @a.id ])
    seen = MatchDigest.create!(user: @owner, matched_user_ids: [ @b.id ], seen_at: Time.current)

    assert_not unseen.seen?
    assert seen.seen?
  end
end
