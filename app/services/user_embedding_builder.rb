require "digest/md5"

class UserEmbeddingBuilder
  DIMENSIONS = 512

  # Vektorun ilk CATEGORY_DIMENSIONS boyutu kategori-ortak hashing icin ayrilir;
  # geri kalan boyutlar skill-kimlik hashing icindir. Iki alt-aralik ayrik oldugu
  # icin bir skill'in kategori bucket'i ile kimlik bucket'i asla cakismaz - bu
  # yuzden kategorili her skill vektorde tam olarak iki boyuta katki verir.
  CATEGORY_DIMENSIONS = 128
  IDENTITY_DIMENSIONS = DIMENSIONS - CATEGORY_DIMENSIONS

  ROLES = %w[teaching learning].freeze

  def self.call(user, role:)
    new(user, role).call
  end

  def initialize(user, role)
    raise ArgumentError, "unknown role: #{role}" unless ROLES.include?(role)

    @user = user
    @role = role
  end

  def call
    vector = Array.new(DIMENSIONS, 0.0)

    @user.user_skills.where(direction: @role).includes(:skill).each do |user_skill|
      skill = user_skill.skill
      next unless skill

      weight = user_skill.weight || 1.0

      vector[category_bucket(skill.category)] += weight if skill.category.present?
      vector[identity_bucket(skill)] += weight
    end

    normalize(vector)
  end

  private

  # Kategori-ortak boyut: ayni kategorideki (ör. "language") farkli skill'ler bu
  # boyutu paylasir, boylece isimleri farkli olsa da bir taban benzerlik kazanir.
  def category_bucket(category)
    Digest::MD5.hexdigest(category.to_s.downcase.strip).to_i(16) % CATEGORY_DIMENSIONS
  end

  # Skill-kimlik boyutu: kimlik alt-araligina (CATEGORY_DIMENSIONS..DIMENSIONS)
  # duser. Isim once SkillAlias uzerinden kanonik ada cozumlenir, sonra hash'lenir;
  # boylece ayni kavramin farkli yazim varyantlari ("Node.js" / "NodeJS") ayni
  # kimlik bucket'ina duser.
  def identity_bucket(skill)
    offset = Digest::MD5.hexdigest(canonical_identity_key(skill)).to_i(16) % IDENTITY_DIMENSIONS
    CATEGORY_DIMENSIONS + offset
  end

  # SkillResolver ile BIREBIR AYNI normalizasyon (name.downcase.strip.delete(" "))
  # ve ayni alias cozumu - tutarlilik icin. Alias bulunursa kimlik, kanonik
  # skill'in adi uzerinden hesaplanir.
  def canonical_identity_key(skill)
    normalized = normalize_name(skill.name)
    aliased = SkillAlias.find_by(alias_name: normalized)
    canonical_name = aliased ? aliased.skill.name : skill.name
    normalize_name(canonical_name)
  end

  def normalize_name(name)
    name.to_s.downcase.strip.delete(" .")
  end

  def normalize(vector)
    norm = Math.sqrt(vector.sum { |v| v * v })
    return vector if norm.zero?

    vector.map { |v| v / norm }
  end
end
