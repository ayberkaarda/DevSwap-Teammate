namespace :embeddings do
  desc "Skill'i olan tum kullanicilar icin teach/learn embedding'lerini zorla yeniden hesaplar"
  task generate_all: :environment do
    user_ids = User.joins(:user_skills).distinct.pluck(:id)

    user_ids.each { |user_id| GenerateUserEmbeddingJob.new.perform(user_id, force: true) }

    puts "#{user_ids.size} kullanici icin embedding (yeniden) hesaplandi (force)."
  end
end
