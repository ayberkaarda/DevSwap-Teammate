require "test_helper"

class BlockTest < ActiveSupport::TestCase
  test "gecerli blok olusturulabilir" do
    block = Block.new(blocker: users(:one), blocked: users(:two))
    assert block.valid?
  end

  test "kendini engelleyemez" do
    block = Block.new(blocker: users(:one), blocked: users(:one))
    assert_not block.valid?
    assert_includes block.errors[:blocked_id], "kendini engelleyemezsin"
  end

  test "ayni ikili icin ikinci blok gecersizdir (unique)" do
    Block.create!(blocker: users(:one), blocked: users(:two))
    dup = Block.new(blocker: users(:one), blocked: users(:two))
    assert_not dup.valid?
  end

  test "blocked_between? her iki yonde de true doner" do
    Block.create!(blocker: users(:one), blocked: users(:two))
    assert Block.blocked_between?(users(:one), users(:two))
    assert Block.blocked_between?(users(:two), users(:one))
  end

  test "blocked_between? iliski yoksa false" do
    assert_not Block.blocked_between?(users(:one), users(:two))
  end

  test "blocks? yonludur" do
    Block.create!(blocker: users(:one), blocked: users(:two))
    assert Block.blocks?(users(:one), users(:two))
    assert_not Block.blocks?(users(:two), users(:one))
  end

  test "user.blocking? ve blocked_users iliskisi" do
    users(:one).blocks_made.create!(blocked: users(:two))
    assert users(:one).blocking?(users(:two))
    assert_not users(:two).blocking?(users(:one))
    assert_includes users(:one).blocked_users, users(:two)
  end
end
