class WeeklyMatchDigestJob < ApplicationJob
  queue_as :default

  # Haftalik "bu hafta senin icin en iyi eslesmeler" digest'i. Skill'i olan her
  # kullanici icin MatchFinder'in ilk 3 adayini secip DB'ye bir MatchDigest satiri
  # yazar. PostNotification gibi email/bildirim tarafi YOK, sadece DB kaydi.
  TOP_MATCHES = 3

  def perform
    created = 0

    # Sadece en az bir UserSkill satiri olan kullanicilar aday: skill'i olmayan
    # kullanici icin MatchFinder'i hic cagirmiyoruz (bosuna vektor/pgvector maliyeti).
    # .distinct + find_each birlikte guvenilir calismadigi icin once id'leri
    # pluck edip tekil hale getiriyoruz, sonra find_each ile batch'liyoruz.
    user_ids = User.joins(:user_skills).distinct.pluck(:id)

    User.where(id: user_ids).find_each do |user|
      matches = MatchFinder.call(user).first(TOP_MATCHES)
      next if matches.empty?

      MatchDigest.create!(user: user, matched_user_ids: matches.map(&:id))
      created += 1
    end

    Rails.logger.info("[WeeklyMatchDigestJob] #{created} digest olusturuldu.")
  end
end
