# Genel/kategori odalari (idempotent). find_or_create_by! yeni kaydi olusturur;
# rules metni ise (yeni odaya blok icinde, mevcut odaya asagidaki backfill ile)
# her calistirmada garanti altina alinir. DM (private) odalarin rules'i bostur.
ROOMS = [
  { slug: "genel",            name: "Genel",            position: 0, rules: "Saygılı ol, spam yapma, konudan sapma. Herkese açık genel sohbet alanıdır." },
  { slug: "backend",          name: "Backend",          position: 1, rules: "Sunucu tarafı, veritabanı ve API konularını konuş. Kod paylaşırken ``` blok kullan." },
  { slug: "frontend",         name: "Frontend",         position: 2, rules: "Arayüz, CSS ve JS tartışmaları burada. Ekran görüntüsü yerine kod örneği tercih et." },
  { slug: "kariyer",          name: "Kariyer",          position: 3, rules: "İş ilanları, maaş ve kariyer tavsiyeleri. Reklam ve spam kesinlikle yasak." },
  { slug: "cloud",            name: "Cloud & DevOps",   position: 4, rules: "Bulut altyapısı, CI/CD ve container konuları. Gizli anahtar/credential paylaşma." },
  { slug: "machine-learning", name: "Machine Learning", position: 5, rules: "Model, veri ve makine öğrenmesi tartışmaları. Kaynak ve veri setlerini referansla." },
  { slug: "game-development", name: "Game Development",  position: 6, rules: "Oyun motorları, grafik ve tasarım. Yapıcı geri bildirim ver, spoiler paylaşma." },
  { slug: "isletim-sistemi",  name: "İşletim Sistemi",  position: 7, rules: "Çekirdek, süreç ve sistem programlama. Tehlikeli komutları uyarı olmadan paylaşma." }
].freeze

ROOMS.each do |attrs|
  room = ChatRoom.find_or_create_by!(slug: attrs[:slug]) do |r|
    r.name = attrs[:name]
    r.position = attrs[:position]
    r.rules = attrs[:rules]
  end

  # Mevcut (onceden olusturulmus) odalar icin rules bos ise doldur.
  room.update!(rules: attrs[:rules]) if room.rules.blank?
end
