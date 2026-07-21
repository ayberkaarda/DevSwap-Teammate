# db/seeds.rb NORMALDE HİÇBİR ŞEY SİLMEZ.
#
# Varsayılan davranış: eksik demo kullanıcı/skill/user_skill kayıtlarını
# idempotent şekilde (find_or_create_by!) ekler. Var olan veriye dokunmaz,
# tekrar tekrar çalıştırılabilir, hata vermez ve duplicate oluşturmaz.
#
# Yıkıcı sıfırlama (UserSkill/User/Skill.delete_all) SADECE aşağıdaki İKİ
# koşul da doğruysa çalışır:
#   1) Rails.env.development?
#   2) ENV["SEED_RESET"] == "1"
#
# Kullanım (bilerek ve isteyerek dev verisini sıfırlamak istiyorsan):
#   SEED_RESET=1 bin/rails db:seed
#
# Bu koruma, geçmişte "bin/rails db:seed" içeriği önceden kontrol edilmeden
# çalıştırıldığında koşulsuz delete_all zincirinin gerçek dev verisini
# kalıcı olarak silmesi yüzünden eklendi.

if Rails.env.development? && ENV["SEED_RESET"] == "1"
  UserSkill.delete_all
  User.delete_all
  Skill.delete_all
end

# Global Yetenekleri Oluşturma (idempotent)
ruby = Skill.find_or_create_by!(name: "Ruby on Rails") { |s| s.category = "Backend" }
java = Skill.find_or_create_by!(name: "Java / Spring Boot") { |s| s.category = "Backend" }
angular = Skill.find_or_create_by!(name: "Angular") { |s| s.category = "Frontend" }
unreal = Skill.find_or_create_by!(name: "Unreal Engine 5") { |s| s.category = "3D/Game" }

# Kullanıcıları Oluşturma (idempotent)
user1 = User.find_or_create_by!(email: "ayberk@devswap.com") do |u|
  u.name = "Ayberk"
  u.bio = "Java ve Angular biliyorum, Rails öğrenmek istiyorum."
  u.role = "developer"
end
user2 = User.find_or_create_by!(email: "arda@devswap.com") do |u|
  u.name = "Arda"
  u.bio = "Yılların Rails geliştiricisiyim, Unreal Engine merakım var."
  u.role = "developer"
end

# Yetenek İlişkilerini Kurma (idempotent) (teaching: Sahip olduğu, learning: Öğrenmek istediği)
UserSkill.find_or_create_by!(user: user1, skill: java, direction: "teaching")
UserSkill.find_or_create_by!(user: user1, skill: angular, direction: "teaching")
UserSkill.find_or_create_by!(user: user1, skill: ruby, direction: "learning")


UserSkill.find_or_create_by!(user: user2, skill: ruby, direction: "teaching")
UserSkill.find_or_create_by!(user: user2, skill: unreal, direction: "learning")

puts "🚀 Veritabanı başarıyla senkronize edildi (idempotent)! #{User.count} kullanıcı ve #{Skill.count} yetenek mevcut."

# Kanonik (GitHub Linguist ile birebir eşleşen) yetenek havuzunu idempotent şekilde ekle
load Rails.root.join("db/seeds/canonical_skills.rb")

# Bilinen yazım varyantları için alias tablosunu idempotent şekilde ekle
load Rails.root.join("db/seeds/skill_aliases.rb")

# Sekmeli sohbet odalarını idempotent şekilde ekle
load Rails.root.join("db/seeds/chat_rooms.rb")

puts "🚀 Veritabanı başarıyla seed edildi! #{User.count} kullanıcı ve #{Skill.count} yetenek eklendi."


# Kanonik (GitHub Linguist ile birebir eşleşen) yetenek havuzunu idempotent şekilde ekle
load Rails.root.join("db/seeds/canonical_skills.rb")
