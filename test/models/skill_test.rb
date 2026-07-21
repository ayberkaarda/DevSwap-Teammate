require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "has many users through user_skills" do
    assert_includes skills(:one).users, users(:one)
  end

  test "destroying a skill destroys its user_skills" do
    skill = skills(:one)
    assert_difference("UserSkill.count", -1) do
      skill.destroy
    end
  end
end
