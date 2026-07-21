require "test_helper"

class UserSkillTest < ActiveSupport::TestCase
  test "source sadece manual veya github olabilir" do
    user_skill = user_skills(:one)
    user_skill.source = "manual"
    assert user_skill.valid?

    user_skill.source = "github"
    assert user_skill.valid?

    user_skill.source = "invalid"
    assert_not user_skill.valid?
  end

  test "kullanici ve skill'e ait olmali" do
    assert_equal users(:one), user_skills(:one).user
    assert_equal skills(:one), user_skills(:one).skill
  end

  test "direction teach/learn ayrimini tasir" do
    assert_equal "teaching", user_skills(:one).direction
    assert_equal "learning", user_skills(:two).direction
  end
end
