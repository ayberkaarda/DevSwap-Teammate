require "test_helper"

class SkillResolverTest < ActiveSupport::TestCase
  test "bilinmeyen yeni bir isim verilince yeni Skill ve karsilik gelen SkillAlias olusturulur" do
    assert_difference [ "Skill.count", "SkillAlias.count" ], 1 do
      skill = SkillResolver.call("Elixir Phoenix", category: "framework")

      assert skill.persisted?
      assert_equal "Elixir Phoenix", skill.name
      assert_equal "framework", skill.category
    end

    alias_record = SkillAlias.find_by(alias_name: "elixirphoenix")
    assert alias_record.present?
    assert_equal "Elixir Phoenix", alias_record.skill.name
  end

  test "onceden alias tanimli bir varyant verilince yeni Skill olusturulmaz, var olan kanonik Skill doner" do
    node = Skill.create!(name: "Node.js", category: "language")
    SkillAlias.create!(alias_name: "nodejs", skill: node)

    assert_no_difference "Skill.count" do
      resolved = SkillResolver.call("NodeJS")

      assert_equal node.id, resolved.id
    end
  end

  test "ayni ismin buyuk/kucuk harf veya bosluk farkiyla ikinci kez cagrilmasi yeni Skill yaratmaz" do
    first = SkillResolver.call("PostgreSQL", category: "tool")

    assert_no_difference "Skill.count" do
      second = SkillResolver.call("  postgresql  ")

      assert_equal first.id, second.id
    end
  end
end
