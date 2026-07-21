# Yazma (write) noktalarinda skill isimlerini kanoniklestirir: ayni kavramin
# farkli yazim varyantlari (ör. "Node.js" / "NodeJS") icin tekrar tekrar yeni
# Skill kaydi olusmasini engeller. Normalizasyon algoritmasi MatchFinder#normalized_skill_name
# ile BIREBIR AYNI olmali (name.downcase.strip.delete(" .")) - tutarlilik icin.
class SkillResolver
  def self.call(name, category: nil)
    new(name, category).call
  end

  def initialize(name, category)
    @raw_name = name.to_s.strip
    @category = category
  end

  def call
    return nil if @raw_name.blank?

    key = normalize(@raw_name)
    existing = SkillAlias.find_by(alias_name: key)
    return existing.skill if existing

    skill = Skill.find_or_create_by!(name: @raw_name) do |s|
      s.category = @category if @category
    end
    SkillAlias.find_or_create_by!(alias_name: key) { |a| a.skill = skill }
    skill
  end

  private

  def normalize(name)
    name.downcase.strip.delete(" .")
  end
end
