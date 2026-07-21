# Mimari İnceleme — İlgili Alıntılar

> Bu belge, proje dışında hazırlanmış bir mimari inceleme raporundan repoya
> referans amaçlı taşınan alıntılardır. Kaynak belgenin tamamı değildir.

## §1 — Darboğaz Analizi: İlk patlayacak yer: Solid Cable'ın polling mimarisi

Solid Cable, Redis pub/sub'ın aksine push değil poll yapar: her Puma süreci
solid_cable_messages tablosunu polling_interval aralığıyla sorgular.
10.000 CCU'da matematik acımasızdır:
- 10.000 eşzamanlı WebSocket bağlantısı için kabaca 10–20 Puma süreci gerekir
  (süreç başına ~500–1000 bağlantı).
- Her süreç saniyede 10 kez poll ederse: saniyede 100–200 sorgu, sadece "yeni
  mesaj var mı?" diye sormak için.
- Asıl katil sorgu hacmi değil, solid_cable_messages tablosundaki yazma/silme
  çalkantısı (churn): her broadcast bir INSERT, retention temizliği sürekli
  DELETE. Bu, tablonun ve indekslerinin şişmesine (bloat) ve autovacuum'un
  yetişememesine yol açar. Sistem "yavaş yavaş" değil, vacuum geri kaldığında
  kaskad halinde çöker.

Önlemler (öncelik sırasıyla):
1. Polling aralığını kademelendirin. 0.1s bir sohbet uygulaması refleksidir;
   bildirim akışları için 0.5–1s insan gözüyle ayırt edilemez.
2. Yayın granülaritesini daraltın. Tek global stream (terminal_chat_channel)
   ile 10.000 kullanıcının hepsi her mesajı alır — O(N²) trafik. Kullanıcı-
   bazlı veya oda-bazlı stream'lere geçiş, 10K CCU planının ÖNKOŞULUDUR,
   opsiyonu değil.
3. message_retention'ı kısaltın. Cable mesajları geçicidir; 1 saat bile
   cömerttir. Küçük tablo = hızlı poll = mutlu vacuum.
4. Cable veritabanını fiziksel olarak ayrı bir PostgreSQL instance'ına
   taşıyın — WAL'ını ve buffer cache'ini kirletmesini engeller. Bu hâlâ
   "Just Postgres"tir, sadece iki tane.

## Üçüncü (sinsi) darboğaz: bağlantı havuzu aritmetiği

Her Puma süreci BEŞ ayrı havuz açar (primary/cache/queue/cable/telemetry — telemetry
Faz 12'de activity_logs + telemetry_snapshots'ı primary'den izole etmek için eklendi).
20 süreç × 5 DB × 5 bağlantı = 500 bağlantı; Solid Queue worker'ları eklenince
varsayılan max_connections (100) duvarına DAHA DA ERKEN çarparsınız (4 DB'ye göre
%25 daha fazla bağlantı baskısı). max_connections'ı bilinçli hesaplayın ve
PgBouncer'ı (transaction mode) yol haritasına koyun — telemetry DB'si özellikle
PgBouncer'a iyi aday: partition'lı append-only yazımlar transaction-mode pooling'le
sorunsuz çalışır, uzun süreli session/prepared-statement bağımlılığı yok.


## §1 — Darboğaz Analizi: İkinci patlama noktası: Pgvector eşleştirme sorguları

- Exact nearest-neighbor (sıralı tarama) ilk 1.000 kullanıcıda bile hissedilir.
  HNSW indeksi şarttır; IVFFlat'e göre daha yüksek build maliyeti ama çok daha
  iyi ve veri büyüdükçe yeniden eğitim (re-clustering) gerektirmez.
- Asıl tuzak: HNSW indeksi + sık güncellenen vektörler. GitHub taraması her
  login'de vektörleri yeniden yazarsa, HNSW indeksi sürekli parçalanır.
  Vektör güncellemesi: kullanıcı başına en fazla günde bir yeniden hesaplama;
  değişim eşiği (örn. dil dağılımı %5'ten az değiştiyse vektöre dokunma).
- İkinci tuzak: filtreli vektör araması. HNSW filtreyle birleşince recall düşer
  veya indeks devre dışı kalır. Çözüm: önce vektörle geniş aday kümesi çek
  (örn. top-200), sonra ilişkisel filtreyi uygula (post-filtering). Bu iki
  aşamalı deseni baştan tasarıma koyun.
- Eşleştirme sonuçlarını Solid Cache'e yazın: eşleşme listesi gerçek zamanlı
  olmak zorunda değil, 15 dakikalık cache 10K CCU'daki vektör sorgu yükünü
  ~%95 azaltır.

## §2'den ilgili not — Vektör tablosu

Vektörü users tablosuna gömmeyin. Vektör ~6KB/satır; users tablosuna eklerseniz
her User.find bu yükü taşır, TOAST devreye girer ve users'ın autovacuum profili
bozulur. user_skill_vectors gibi 1:1 ayrı tablo, HNSW indeksinin de kendi
hayatını yaşamasını sağlar.


## §2 — Veritabanı İzolasyonu

Schema ayrımı yanlış araç; doğru araç ayrı-veritabanı deseni.
Gerekçe: Aynı veritabanı içindeki schema'lar (telemetry.events gibi) yalnızca
ad alanı izolasyonu sağlar. Buffer cache, WAL, autovacuum worker'ları,
checkpoint'ler ortaktır. Telemetry tablosu saniyede yüzlerce satır yazarken
Users tablosunun sıcak sayfalarını cache'ten söker — schema ayrımı bunu
engellemez.

Katmanlı izolasyon:
| Veri sınıfı | Büyüme profili | İzolasyon stratejisi |
|---|---|---|
| Users, Posts, Messages (çekirdek) | Yavaş, kıymetli | primary |
| Telemetry / log olayları | Çok hızlı, append-only, süreli | Beşinci mantıksal DB (telemetry:) — Rails 8 multi-DB; içinde aya/haftaya göre native range partitioning |
| Pgvector yetenek vektörleri | Orta hız, güncellenir | primary'de ama ayrı tablo |
| Cable/Queue/Cache | Yüksek churn, geçici | ayrı instance'a taşınabilir |

Kritik detaylar:
1. Vektörü users tablosuna gömmeyin. (mevcut not — bu maddenin yeri burası)
2. Telemetry'de partisyon + DROP PARTITION = bedava retention. Milyonlarca
   satırı DELETE ile silmek vacuum felaketidir; eski ayın partisyonunu
   düşürmek milisaniyeliktir. Telemetry tasarımının bir numaralı kuralı budur.
3. Telemetry'ye senkron YAZMAYIN. Request döngüsünden telemetry insert'i
   geçirmeyin; olayları Solid Queue üzerinden toplu (batch) yazın. Bu hem
   request latency'sini korur hem de yazımları büyük, verimli transaction'lara
   dönüştürür.
4. Schema ayrımını tamamen çöpe atmayın — tek DB içinde düzen için (örn.
   telemetry DB'si içinde raw / aggregated schema'ları) hâlâ şık bir araçtır.

## Faz 4 (orijinal plan, tamamlanmamış maddeler)
14. Beşinci mantıksal DB (telemetry:) + aylık range partitioning + DROP
    PARTITION retention'ı.
15. Olay toplama: request döngüsünden değil, Solid Queue batch job'ları
    üzerinden yazım.
16. Dashboard okumaları için önceden toplanmış tablolar — dashboard asla ham
    telemetry tablosunu taramamalı.

