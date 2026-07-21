class GenerateUserEmbeddingJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: ->(user_id) { user_id }, duration: 5.minutes

  SIMILARITY_SKIP_THRESHOLD = 0.98
  MIN_RECOMPUTE_INTERVAL = 1.day
  DISTRIBUTION_CHANGE_THRESHOLD = 0.05

  def perform(user_id, force: false)
    user = User.find_by(id: user_id)
    return if user.nil?

    if user.user_skills.none?
      existing_record = UserSkillVector.find_by(user: user)

      if existing_record && (existing_record.embedding_teach.present? || existing_record.embedding_learn.present? || existing_record.generated_at.present?)
        existing_record.update!(embedding_teach: nil, embedding_learn: nil, skill_distribution: {}, generated_at: nil)
        Rails.logger.info "[GenerateUserEmbeddingJob] Kullanıcı ##{user.id}: hiç skill kalmadı, embedding kaydı temizlendi."
      end

      return
    end

    record = UserSkillVector.find_or_initialize_by(user: user)

    if !force && record.persisted? && record.generated_at.present? && record.generated_at > MIN_RECOMPUTE_INTERVAL.ago
      Rails.logger.info "[GenerateUserEmbeddingJob] Kullanıcı ##{user.id}: son hesaplamadan bu yana #{MIN_RECOMPUTE_INTERVAL.inspect} geçmedi, atlandı."
      return
    end

    new_distribution = language_distribution(user)

    if !force && record.persisted? && record.skill_distribution.present?
      change = distribution_change(record.skill_distribution, new_distribution)
      if change < DISTRIBUTION_CHANGE_THRESHOLD
        Rails.logger.info "[GenerateUserEmbeddingJob] Kullanıcı ##{user.id}: dil dağılımı değişimi ihmal edilebilir (#{change.round(4)}), atlandı."
        return
      end
    end

    new_teach_vector = vector_for_role(user, "teaching")
    new_learn_vector = vector_for_role(user, "learning")

    if !force && record.persisted?
      teach_changed = vector_changed?(record.embedding_teach, new_teach_vector)
      learn_changed = vector_changed?(record.embedding_learn, new_learn_vector)

      unless teach_changed || learn_changed
        Rails.logger.info "[GenerateUserEmbeddingJob] Kullanıcı ##{user.id}: teach ve learn vektörleri ihmal edilebilir değişti, atlandı."
        return
      end
    end

    record.embedding_teach = new_teach_vector
    record.embedding_learn = new_learn_vector
    record.skill_distribution = new_distribution
    record.generated_at = Time.current
    record.save!

    Rails.logger.info "[GenerateUserEmbeddingJob] Kullanıcı ##{user.id}: embedding güncellendi."
  end

  private

  # Kullanicinin o rolde hic skill'i yoksa nil doner (sifir-vektor DEGIL).
  # Boylece ANN sorgusu (UserSkillVector.nearest_neighbors) bu kullaniciyi
  # dogal olarak eler (gem NULL kolonlari zaten disliyor) ve sifir vektorle
  # kosinus benzerligi hesaplarken bolme hatasi/NaN olusmaz.
  def vector_for_role(user, role)
    return nil unless user.user_skills.exists?(direction: role)

    UserEmbeddingBuilder.call(user, role: role)
  end

  def vector_changed?(old_vector, new_vector)
    return false if old_vector.blank? && new_vector.nil?
    return true if old_vector.blank? || new_vector.nil?

    cosine_similarity(old_vector.to_a, new_vector) < SIMILARITY_SKIP_THRESHOLD
  end

  def language_distribution(user)
    weights = Hash.new(0.0)
    user.user_skills.joins(:skill).where(skills: { category: "language" }).each do |user_skill|
      weights[user_skill.skill_id.to_s] += (user_skill.weight || 0.0)
    end

    total = weights.values.sum
    return {} if total.zero?

    weights.transform_values { |w| w / total }
  end

  def distribution_change(old_distribution, new_distribution)
    keys = old_distribution.keys | new_distribution.keys
    total_variation = keys.sum { |key| (old_distribution[key].to_f - new_distribution[key].to_f).abs }
    total_variation / 2.0
  end

  def cosine_similarity(a, b)
    dot = a.zip(b).sum { |x, y| x * y }
    norm_a = Math.sqrt(a.sum { |x| x * x })
    norm_b = Math.sqrt(b.sum { |x| x * x })
    return 0.0 if norm_a.zero? || norm_b.zero?

    dot / (norm_a * norm_b)
  end
end
