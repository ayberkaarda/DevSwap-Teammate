require "delegate"

class MatchFinder
  # bkz. docs/architecture-review.md #1: HNSW + filtreli arama tuzagi -
  # once vektorle genis aday kumesi cek (top-N), sonra iliskisel filtre uygula.
  CANDIDATE_POOL_SIZE = 200
  CACHE_TTL = 15.minutes
  REASON_SKILL_LIMIT = 2

  # Gosterilecek "eslesme kalitesi" yuzdesi icin overlap sinyalinin doygunluk
  # sabiti. skill_overlap her eslesen skill icin (benim agirligim + adayin
  # agirligi) toplar; varsayilan agirlik 1.0 oldugundan tek skill kesisimi
  # strength=2.0 verir. strength/(strength+SAT) haritasi: tek kesisim -> 0.5,
  # daha cok/agir kesisim -> 1.0'a dogru doygunlasir.
  OVERLAP_SATURATION = 2.0

  # User'i sarip view'da match.name / match.avatar_url gibi butun User
  # metodlarinin calismasini saglar, ustune eslesme skoru/karsilikliligi/
  # nedenini ekler.
  class Match < SimpleDelegator
    attr_reader :score, :reciprocal, :reason, :display_score

    # score        : ham kosinus tabanli skor (0..1). Siralama/rating boost bu
    #                deger uzerinden yapilir - DEGISTIRILMEMELIDIR.
    # display_score : kullaniciya gosterilecek "eslesme kalitesi" (0..1). Ham
    #                kosinus ile normalize edilmis skill-overlap sinyalini
    #                harmanlar; boylece gercek bir skill kesisimi olan aday
    #                (embedding kosinus'u 0 olsa bile) anlamli bir yuzde gosterir.
    def initialize(user, score:, reciprocal:, reason:, display_score:)
      super(user)
      @score = score
      @reciprocal = reciprocal
      @reason = reason
      @display_score = display_score
    end

    def quality_percent
      (display_score * 100).round
    end
  end

  def self.call(user)
    new(user).call
  end

  def initialize(user)
    @user = user
  end

  def call
    vector = UserSkillVector.find_by(user: @user)
    return fallback_candidates if vector.nil? || (vector.embedding_teach.blank? && vector.embedding_learn.blank?)

    candidates = Rails.cache.fetch(cache_key(vector), expires_in: CACHE_TTL) { ranked_candidate_ids(vector) }
    hydrate(apply_relational_filters(candidates))
  end

  private

  def ranked_candidate_ids(vector)
    teach_pool = vector.embedding_teach.present? ? candidate_pool(:embedding_learn, vector.embedding_teach) : {}
    learn_pool = vector.embedding_learn.present? ? candidate_pool(:embedding_teach, vector.embedding_learn) : {}

    merge_and_rank(teach_pool, learn_pool)
  end

  def candidate_pool(column, vector_values)
    UserSkillVector
      .nearest_neighbors(column, vector_values, distance: "cosine")
      .first(CANDIDATE_POOL_SIZE)
      .each_with_object({}) { |record, scores| scores[record.user_id] = 1.0 - record.neighbor_distance }
  end

  # Karsilikli tam swap (iki yonlu de eslesen aday) her zaman tek yonlu
  # eslesmenin onune gecer - urunun ozu "ben sana ogretirim, sen bana
  # ogretirsin" oldugu icin tam swap kategorik olarak daha degerli.
  # Aynı katmanda skor: mevcut yon skorlarinin ortalamasi (0..1 araliginda
  # kalir, ileride kalite skoru gostermek icin tutarli).
  def merge_and_rank(teach_pool, learn_pool)
    candidate_ids = teach_pool.keys | learn_pool.keys
    skill_weights_by_user = bulk_skill_weights(candidate_ids)
    ratings_by_user = bulk_average_ratings(candidate_ids)

    candidate_ids
      .map do |id|
        scores = [ teach_pool[id], learn_pool[id] ].compact
        reciprocal = teach_pool.key?(id) && learn_pool.key?(id)
        rating = ratings_by_user[id]
        boost = rating.present? ? (rating.to_f / 5.0) * 0.1 : 0.0
        raw_score = scores.sum / scores.size.to_f
        overlap = skill_overlap(id, teach_pool.key?(id), learn_pool.key?(id), skill_weights_by_user)
        {
          id: id,
          reciprocal: reciprocal,
          score: raw_score,
          rating_boosted_score: raw_score + boost,
          overlap: overlap,
          display_score: display_quality(raw_score, overlap)
        }
      end
      .sort_by { |c| [ c[:reciprocal] ? 0 : 1, -c[:rating_boosted_score] ] }
      .then { |ranked| attach_reasons(ranked) }
  end

  # Gosterilecek eslesme kalitesi (0..1). Iki bagimsiz kaniti "noisy-OR" ile
  # birlestirir: (1) ham embedding kosinus benzerligi, (2) gercek eslesen
  # skill'lerin normalize edilmis agirligi. Herhangi biri yuksekse kalite
  # yukselir. Kritik nokta: bag-of-skills embedding modeli, ismi farkli ama
  # iliskili skill'leri (ör. "Ruby on Rails" vs "Ruby") ayri MD5 bucket'lara
  # koydugu icin bu ciftlerin kosinus'u 0 cikar; ancak skill_overlap kesisimi
  # dogru yakaladigindan overlap sinyali kaliteye anlamli bir taban saglar
  # (tek kesisim -> ~%50), boylece gercek bir "kesişim" olan aday artik %0
  # gostermez. Ham `score` (siralama/boost icin) bundan etkilenmez.
  def display_quality(cosine_score, overlap)
    cosine = cosine_score.clamp(0.0, 1.0)
    return cosine if overlap.empty?

    strength = overlap.values.sum
    overlap_component = strength / (strength + OVERLAP_SATURATION)
    1.0 - (1.0 - cosine) * (1.0 - overlap_component)
  end

  # Aday basina ayri sorgu atmadan (N+1 yok), TUM adaylarin teaching/learning
  # skill agirliklarini tek sorguda cekip user_id'ye gore gruplar.
  def bulk_skill_weights(candidate_ids)
    grouped = Hash.new { |h, k| h[k] = { "teaching" => {}, "learning" => {} } }
    return grouped if candidate_ids.empty?

    UserSkill.where(user_id: candidate_ids, direction: %w[teaching learning]).each do |us|
      grouped[us.user_id][us.direction][us.skill_id] = us.weight || 1.0
    end

    grouped
  end

  # Aday basina ayri sorgu atmadan (N+1 yok), TUM adaylarin ortalama puanini
  # tek sorguda ceker - bulk_skill_weights ile ayni desen.
  def bulk_average_ratings(candidate_ids)
    return {} if candidate_ids.empty?

    User.where(id: candidate_ids).pluck(:id, :average_rating).to_h
  end

  def my_skill_weights(role)
    @my_skill_weights ||= {}
    @my_skill_weights[role] ||= @user.user_skills.where(direction: role)
      .each_with_object({}) { |us, h| h[us.skill_id] = us.weight || 1.0 }
  end

  # teach_direction: benim teaching vektorum onun learning'ine eslesti.
  # learn_direction: benim learning vektorum onun teaching'ine eslesti.
  def skill_overlap(candidate_id, teach_direction, learn_direction, skill_weights_by_user)
    candidate_weights = skill_weights_by_user[candidate_id]
    overlap = Hash.new(0.0)

    if teach_direction
      match_normalized_skills(my_skill_weights("teaching"), candidate_weights["learning"]).each do |my_id, cand_id|
        overlap[my_id] += my_skill_weights("teaching")[my_id] + candidate_weights["learning"][cand_id]
      end
    end

    if learn_direction
      match_normalized_skills(my_skill_weights("learning"), candidate_weights["teaching"]).each do |my_id, cand_id|
        overlap[my_id] += my_skill_weights("learning")[my_id] + candidate_weights["teaching"][cand_id]
      end
    end

    overlap
  end

  # ID'ler farkli olsa bile isimleri (bosluk/noktalama olmadan) ayni olan
  # skill'leri eslestirir. Ayrica alt/ust teknoloji hiyerarsisini de tanir:
  # biri digerini substring olarak iceriyorsa (ör. "rubyonrails" icinde "ruby")
  # eslesme sayilir - boylece "Ruby on Rails" ogreten biri "Ruby" arayana cikar.
  def match_normalized_skills(my_skills, cand_skills)
    matches = []
    my_skills.keys.each do |my_id|
      my_norm = normalized_skill_name(my_id)
      cand_id = cand_skills.keys.find { |cid| skill_names_related?(my_norm, normalized_skill_name(cid)) }
      matches << [ my_id, cand_id ] if cand_id
    end
    matches
  end

  # Iki normalize edilmis skill ismi iliskili mi? Tam esitlik veya (alt/ust
  # teknoloji icin) substring icerme. Kisa isimlerde (< 3 karakter) substring
  # kontrolu kapali - "go" gibi isimlerin "django" gibi her yerde yanlislikla
  # eslesmesini onlemek icin (tam esitlik yine de calisir).
  def skill_names_related?(name_a, name_b)
    return true if name_a == name_b
    return false if name_a.length < 3 || name_b.length < 3

    name_a.include?(name_b) || name_b.include?(name_a)
  end

  def normalized_skill_name(skill_id)
    @skill_names_cache ||= Skill.pluck(:id, :name).to_h
    name = @skill_names_cache[skill_id].to_s
    name.downcase.strip.delete(" .")
  end

  def attach_reasons(ranked)
    all_skill_ids = ranked.flat_map { |c| c[:overlap].keys }.uniq
    skill_names = Skill.where(id: all_skill_ids).pluck(:id, :name).to_h

    ranked.map do |c|
      c.merge(reason: build_reason(c[:overlap], skill_names))
    end
  end

  def build_reason(overlap, skill_names)
    return nil if overlap.empty?

    names = overlap.sort_by { |_, weight| -weight }
      .first(REASON_SKILL_LIMIT)
      .map { |skill_id, _| skill_names[skill_id] }
      .compact

    return nil if names.empty?

    "#{names.join(" + ")} kesişimi"
  end

  # Iliskisel post-filter: kendini ve (iki yonlu) bloklu kullanicilari ele.
  # Taraflardan biri digerini engellemisse aday listesinde gorunmemeli.
  def apply_relational_filters(candidates)
    candidates.reject do |c|
      c[:id] == @user.id || Block.blocked_between?(@user, User.new(id: c[:id]))
    end
  end

  def hydrate(candidates)
    return [] if candidates.empty?

    users_by_id = User.where(id: candidates.map { |c| c[:id] }).index_by(&:id)
    candidates.filter_map do |c|
      user = users_by_id[c[:id]]
      next unless user

      Match.new(user, score: c[:score], reciprocal: c[:reciprocal], reason: c[:reason], display_score: c[:display_score])
    end
  end

  def fallback_candidates
    User.where.not(id: @user.id).to_a
  end

  def cache_key(vector)
    "dashboard_matches:v1:#{@user.id}:#{vector.generated_at.to_i}"
  end
end
