class MatchCalculationJob < ApplicationJob
  queue_as :default

  # Bir Post yayınlandığında: post içeriğinde geçen skill isimlerini tespit et,
  # o skill'lere sahip (teaching VEYA learning) kullanıcılara (post sahibi hariç)
  # "bu ilgini çekebilir" bildirimi gönder.
  def perform(post)
    content = post.content.to_s
    return if content.blank?

    # Tüm skill'ler küçük bir tablo (~90 kayıt) — tek sorguda çek.
    skills = Skill.pluck(:id, :name)

    # Kelime sınırı (word boundary) ile eşleştir: "Go" skill'i "Going" içinde
    # yanlışlıkla eşleşmesin.
    matched = skills.select do |_id, name|
      name.present? && content.match?(/\b#{Regexp.escape(name)}\b/i)
    end
    return if matched.empty?

    matched_skill_ids = matched.map(&:first)

    # Bu skill'lerden herhangi birine sahip (teaching veya learning) kullanıcılar,
    # post sahibi hariç. Her aday için eşleşen ilk skill'i tutuyoruz.
    candidate_rows = UserSkill
                     .where(skill_id: matched_skill_ids)
                     .where.not(user_id: post.user_id)
                     .pluck(:user_id, :skill_id)

    return if candidate_rows.empty?

    # user_id -> ilk eşleşen skill_id
    skill_by_user = {}
    candidate_rows.each do |user_id, skill_id|
      skill_by_user[user_id] ||= skill_id
    end

    now = Time.current
    records = skill_by_user.map do |user_id, skill_id|
      {
        post_id: post.id,
        user_id: user_id,
        skill_id: skill_id,
        created_at: now,
        updated_at: now
      }
    end

    # Tek toplu insert; [:post_id, :user_id] unique index sayesinde tekrar
    # taramada duplicate oluşmaz (ON CONFLICT DO NOTHING davranışı).
    PostNotification.insert_all(records, unique_by: [ :post_id, :user_id ])

    Rails.logger.info(
      "[MatchCalculationJob] Post ##{post.id}: #{records.size} bildirim oluşturuldu " \
      "(#{matched_skill_ids.size} skill eşleşti)."
    )
  end
end
