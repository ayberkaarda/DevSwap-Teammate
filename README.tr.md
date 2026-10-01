# DevSwap-Teammate

[🇬🇧 English](README.md) | 🇹🇷 Türkçe

**Terminal/hacker estetiğiyle sarılmış, geliştiriciler arası (peer-to-peer) yetenek takası platformu.**

DevSwap, bir yeteneği **öğretmek** isteyen geliştiricileri o yeteneği **öğrenmek** isteyenlerle eşleştirir; bunun için GitHub aktivitesini ve kategori farkındalıklı bir pgvector anlamsal eşleştirme motorunu kullanır. Eşleşen kullanıcılar gerçek zamanlı terminal tarzı sohbet, DM'ler, herkese açık profil, ilerleme paylaşımı için sosyal akış ve tamamen özelleştirilebilir widget tabanlı bir dashboard kazanır — hepsi nostaljik yeşil-siyah terminal arayüzünde (seçebileceğiniz on tema daha ile).

---

## Ekran Görüntüleri

> Playwright ile, demo verisiyle doldurulmuş yerel bir örnekten alındı (koyu tema).

| Dashboard | Sosyal akış |
|---|---|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Sosyal akış](docs/screenshots/posts-feed.png) |

| Herkese açık profil | Herkese açık sohbet odası |
|---|---|
| ![Profil](docs/screenshots/profile.png) | ![Sohbet odası](docs/screenshots/chat-room.png) |

| Eşleşme DM'i | Bildirimler |
|---|---|
| ![Eşleşme DM](docs/screenshots/dm-match.png) | ![Bildirimler](docs/screenshots/notifications.png) |

| Ayarlar | Başlangıç rehberi |
|---|---|
| ![Ayarlar](docs/screenshots/settings.png) | ![Rehber](docs/screenshots/guide.png) |

| Admin: kullanıcılar | Telemetri |
|---|---|
| ![Admin kullanıcılar](docs/screenshots/admin-users.png) | ![Telemetri](docs/screenshots/telemetry.png) |

---

## Teknoloji Yığını

| Katman | Teknoloji |
|---|---|
| Dil | Ruby **4.0.5** |
| Framework | Rails **~> 8.1.3** (Propshaft asset pipeline) |
| Veritabanı | **pgvector** eklentili PostgreSQL (`neighbor` gem'i ile) |
| Frontend | Tailwind CSS, Hotwire (**Turbo** + **Stimulus**), importmap-rails |
| Arka plan işleri / cache / websocket | **Solid Queue**, **Solid Cache**, **Solid Cable** (hepsi veritabanı destekli — Redis gerekmez) |
| Kimlik doğrulama | GitHub OAuth (`omniauth-github`, `omniauth-rails_csrf_protection`) |
| GitHub API | `octokit` (repo tarama) |
| Görseller | `image_processing` (Active Storage varyantları — banner, avatar) |
| Deploy | `kamal` + `thruster` (Docker tabanlı deploy, HTTP asset cache/X-Sendfile) |
| Diğer önemli gem'ler | `bcrypt` (has_secure_password), `jbuilder`, `bootsnap`, `tzinfo-data` (Windows/JRuby) |
| Geliştirme/test | `debug`, `brakeman`, `bundler-audit`, `rubocop-rails-omakase`, `web-console`, `capybara`, `selenium-webdriver` |

---

## Temel Özellikler

### Eşleştirme ve Yetenekler
- **Kategori farkındalıklı pgvector eşleştirme** (`app/services/match_finder.rb`, `app/services/user_embedding_builder.rb`): her kullanıcının ayrı 512 boyutlu "öğretme" ve "öğrenme" embedding'i vardır (`UserSkillVector`). Vektör iki ayrık alt aralığa bölünür — **kategori hash'leme** için 128 boyut (aynı kategorideki farklı yetenekler, örn. "language", ortak bir temel benzerliği paylaşır) ve **yetenek kimliği hash'leme** için kalan 384 boyut (aynı yeteneğin yazım varyantları `SkillAlias` ile çözülerek aynı kovaya düşer). `MatchFinder`, geniş bir aday havuzu (200) üzerinde HNSW kosinüs en-yakın-komşu araması yapar (`neighbor` ile), ardından ilişkisel filtreleri (kendisi, engellemeler) uygular, **karşılıklı** (iki yönlü öğret/öğren) eşleşmeleri tek yönlülerin üstüne sıralar, isteğe bağlı puan artırımı uygular ve ham kosinüs benzerliğini gerçek normalize yetenek adı örtüşmesiyle harmanlayan ayrı bir kullanıcıya dönük **eşleşme kalitesi yüzdesi** hesaplar; böylece gerçek bir yetenek kesişimi asla yanıltıcı biçimde %0 görünmez.
- **Kanonik yetenek havuzu** (`db/seeds/canonical_skills.rb`): 9 kategoride 303 özenle seçilmiş yetenek — Diller, Frontend Framework ve Kütüphaneleri, Backend Framework'leri (Web3/blockchain araçları dahil), Veritabanları ve ORM'ler, Bulut ve DevOps, Makine Öğrenmesi ve Veri Bilimi, Oyun Geliştirme, İşletim Sistemi ve Sistem Yönetimi, Test ve Araçlar.
- **GitHub repo tarama**: bir arka plan işi (`github_scan_job`) kullanıcının repolarını GitHub API ile tarar ve "öğretme" yeteneklerini güven ağırlığıyla otomatik doldurur; taranan her repo için herkese açık profilde görünürlük anahtarı vardır.
- Yetenek kayıtları yeterlilik seviyesi, isteğe bağlı not ve isteğe bağlı kanıt linki taşır; akordeon arayüzünde yetenek bazında düzenlenebilir.

### Sosyal Akış
- İsteğe bağlı başlık + içerik + etiket çipleriyle global post akışı (`/posts`).
- **Beğeni**, **repost**, **kaydetme**, **paylaşma** (postu DM olarak gönderme; alıcı sayısı başkalarına gösterilmez) ve **yorumlar** (kendi beğeni/tepkileriyle).
- En yeni / en çok beğenilen / en çok repost edilen sıralaması, zaman aralığı filtresi (bugün/hafta/ay/hepsi) ve etikete göre gezinme (`/etiket/:tag`).
- GitHub tarzı arama sözdizimi (`PostSearchQuery`): `Users:isim` (yazar alt dizesi), `tag:react,laravel` (herhangi biri eşleşmesi) ve serbest metin — hepsi tek sorguda birleştirilebilir.
- Post başına moderasyon menüsü: şikayet et, "ilgileniyorum"/"ilgilenmiyorum" işaretle (yazarı ileriye dönük yumuşak gizler, Ayarlar'dan geri alınabilir) ve engelle.

### Gerçek Zamanlı Sohbet ve DM'ler
- ActionCable destekli terminal tarzı sohbet (`TerminalChatChannel`): herkese açık konu odaları ve özel 1:1 DM'ler, canlı çevrimiçi rozetleri, yazıyor göstergesi, okundu bilgisi, emoji mesaj tepkileri ve düzenleme/silme (moderatörler herkesin mesajını silebilir).
- **Eşleşmeden doğan DM'ler** (dashboard'daki "Bağlantı Kur" akışıyla açılan) "Match" rozeti taşır ve sohbet sonunda karşılıklı ★1–5 puanlama sunar; **doğrudan DM'ler** (profildeki "mesaj" butonundan açılan) puanlama akışı olmayan normal sohbet gibi davranır.
- DM sekmeleri **kullanıcı bazında kapatılabilir** (`DismissedConversation` — silmeden gizler; yeni mesaj gelirse yeniden belirir) ve okunmamış sayısı rozeti gösterir. Kişi arama kenar çubuğu yeni DM başlatmayı sağlar.
- **Slash komut motoru** (istemci + sunucu etkili), tam set: `/clear`, `/whoami`, `/ping`, `/omni` (kişisel durum: GitHub bağlı mı, yetenek sayıları, embedding var mı), `/help`, `/rules`, `/report <isim>`, `/block <isim>`, `/unblock <isim>`; ayrıca yalnızca staff/admin için sunucu tarafında zorunlu kılınan `/mute <isim> <süre>`, `/unmute <isim>`, `/ban <isim> [süre]`, `/unban <isim>`.

### Sosyal Graf
- Tek yönlü **Takip** sistemi (onay gerekmez); takipçi/takip sayıları ve liste sayfaları (`/u/:id/followers`, `/u/:id/following`).
- Kendi kendine yönetilen **Engelleme** sistemi (staff rolü gerekmez): engelleme, postları/profili iki yönde gizler, yeni DM'leri engeller ve karşı tarafı eşleştirmeden hariç tutar.

### Moderasyon ve Admin Araçları
- Rol tabanlı erişim: üye / moderatör / admin; controller ve model seviyesinde uygulanır (kurucu admin hesabının rolü geri alınamaz).
- Kullanıcılara veya postlara karşı (isteğe bağlı kanıt görseliyle) **Şikayetler**; durum yaşam döngüsü (Beklemede / İncelendi / İşlem Yapıldı / Reddedildi), şikayetçinin kendi "Şikayetlerim" sayfasından izlenebilir.
- **Banlar** (`BannedAccount`, geçici veya kalıcı), **mute'lar** (`Mute`, süreli sohbet susturma), **uyarılar** (`UserWarning`) ve **eskalasyonlar** (`Escalation`).
- **Admin namespace** (`/admin/...`): kullanıcı arama/listeleme, şikayet inceleme (incelendi/işlem yapıldı/reddet/sil) ve widget sıfırlama uçları (bir kullanıcının dashboard veya profil ızgarasını varsayılana zorla sıfırlama).
- **Admin duyuruları** (`AdminBroadcast`): ActionCable ile canlı yayınlanan site geneli duyurular, isteğe bağlı `expires_at` ile; her kullanıcı kendi görünümünde duyuruyu kapatabilir (`AdminBroadcastDismissal`), kapatılan duyurular o kullanıcının bildirim geçmişinde kalır.

### Özelleştirme
- **11 tema** — System, Light, Dark, Dracula, Monokai, Nord, Solarized, Gruvbox, One Dark, Tokyo Night, Matrix (`app/javascript/controllers/theme_controller.js`) — `localStorage`'da saklanır, "System" seçiliyken işletim sistemi koyu mod değişimine tepki verir.
- **Dashboard widget'ları** (`DashboardWidget`, 11 tür: chatbox, match_algorithm, weather, clock, online_users, recent_contacts, notifications, recent_posts, quick_actions, activity_graph, terminal_shortcuts) — sürükle/boyutlandır Gridstack.js ızgarası, widget başına yazı ölçeği ve gizle/geri getir, kullanıcı başına kalıcı, onay korumalı "varsayılana sıfırla" eylemi.
- **Profil widget'ları** (`ProfileWidget`, 5 tür: identity, teaching_skills, learning_skills, github_repos, reposts) — her kullanıcının herkese açık profil sayfasına uygulanan aynı Gridstack tabanlı özelleştirme sistemi; yalnızca profil sahibi düzenleyebilir, ziyaretçiler kaydedilmiş düzenin salt okunur halini görür.

### Bildirimler
- **Post bildirimleri** (`PostNotification`): yeni bir post kullanıcının öğrenme yetenekleriyle eşleştiğinde oluşur; zil menüsü (görülmemiş sayı rozeti) ve öğe başına "ilgileniyorum"/kapat eylemleri olan tam `/notifications` geçmiş sayfası ile gösterilir.
- **Eşleşme özetleri** (`MatchDigest`), yeni eşleşme önerilerini e-posta ile/arayüzde sunan periyodik (haftalık) bir işi besler.
- **Kapatılan konuşmalar** (`DismissedConversation`), kullanıcının alttaki odayı kaybetmeden bir DM sekmesini gizlemesini sağlar.

### Telemetri
- Ayrı bir **PostgreSQL veritabanı** (`telemetry`; `primary`, `cache`, `queue` ve `cable` ile birlikte — ortam başına toplam beş veritabanı, `config/database.yml` içinde yapılandırılır) `TelemetryRecord`/`TelemetrySnapshot` verisini ana uygulama şemasından izole tutar (`db/telemetry_structure.sql`).
- **Yinelenen Solid Queue işleri** (`config/recurring.yml`): `bootstrap_telemetry_tick` (`TelemetryTickJob`, dakikada bir) ve `telemetry_partition_maintenance` (`TelemetryPartitionMaintenanceJob`, her gün 03:00); production ek olarak saatlik `clear_solid_queue_finished_jobs` çalıştırır.
- Admin'e dönük `/telemetry` paneli kuyruk işlerini ve çevrimiçi kullanıcıları gösterir.

### Diğer Önemli Özellikler
- `rails/pwa` ile **PWA desteği** (`/manifest`, `/service-worker`).
- **Uygulama içi başlangıç rehberi** (`/guide`) — profil düzenleme, herkese açık profiller, takip, eşleştirme, sohbet/DM, slash komutları, post atma, GitHub bağlama, bildirimler, engelleme, şikayetler, ayarlar, widget dashboard, admin/moderatör rolleri ve tema seçimini kapsayan 15 bölümlük anlatım.
- **Ayarlar sayfası** (`/settings`): Kaydedilen postlar, "İlgilenmiyorum" tercihleri (`FeedPreference`) ve Engellenen kullanıcıları tek görünümde toplar.
- **Puanlamalar** (`Rating`): eşleşme sıralama artırımını besleyen karşılıklı ★1–5 eşleşme sonu geri bildirimi.
- Admin'e dönük denetim izleri için **aktivite kaydı** (`ActivityLog`).

---

## Dizin Yapısı

```
app/
  controllers/        Dashboard, rooms/messages, postlar ve etkileşimler (likes, reposts,
                       saves, shares, comments), bildirimler, profiller, GitHub
                       repoları, user skills, moderasyon (bans/mutes/warnings/
                       escalations/complaints), admin_broadcasts, admin namespace,
                       sessions (GitHub OAuth), guide, telemetry, chat_commands.
  models/              User, ChatRoom/Message/MessageReaction, Post/Comment/
                       CommentReaction, Like/Repost/SavedPost/PostShare,
                       PostNotification/MatchDigest/DismissedConversation,
                       Skill/SkillAlias/UserSkill/UserSkillVector,
                       GithubRepository, DashboardWidget/ProfileWidget,
                       AdminBroadcast/AdminBroadcastDismissal, Rating, Follow/Block,
                       FeedPreference, moderasyon modelleri (BannedAccount, Mute,
                       UserWarning, Escalation, Complaint), ActivityLog,
                       TelemetryRecord/TelemetrySnapshot.
  services/            Saf Ruby alan mantığı: MatchFinder + UserEmbeddingBuilder
                       (pgvector eşleştirme), PostSearchQuery (akış arama ayrıştırma),
                       SkillResolver (alias/kanonikleştirme).
  channels/            TerminalChatChannel, gerçek zamanlı sohbetin ActionCable kanalı.
  javascript/
    controllers/       Stimulus controller'ları: tema, dashboard/profil Gridstack
                       ızgaraları, sohbet mesajları, DM/kişi arama, bildirimler,
                       etiket seçici, sonsuz kaydırma, toast, saat/hava durumu widget'ları.
    channels/           terminal_chat_channel.js — istemci tarafı sohbet + slash komutları.
  views/
    dashboard/          Widget tabanlı dashboard iskeleti, oda sekmeleri, sohbet paneli ve
                       widget başına partial'lar (app/views/dashboard/widgets/).
    rooms/               Sohbet odası görünümü ve DM kenar çubuğu (kişi arama / kapatılabilir sekmeler).
    guide/               15 bölümlük başlangıç rehberi.
    pwa/                 PWA manifest ve service worker şablonları.
db/
  seeds/               Seed verisi, canonical_skills.rb (~300 yetenekli havuz) dahil.
  telemetry_structure.sql   Ayrı telemetri veritabanının şeması.
config/
  database.yml         Beş veritabanlı kurulum: primary, cache, queue, cable, telemetry.
  recurring.yml        Solid Queue yinelenen iş takvimi.
  routes.rb            Tüm route/özellik yüzeyi.
```

---

## Kurulum ve Yerel Geliştirme

### Gereksinimler
- Ruby **4.0.5** (`.ruby-version` dosyasına bakın)
- Rails **~> 8.1.3**
- **pgvector** eklentisi kullanılabilir PostgreSQL (`neighbor` gem'i için gerekli)
- Bundler

### 1. Bağımlılıkları kurun
```bash
git clone <repo-url>
cd dev_swap
bundle install
```

### 2. Veritabanını yapılandırın
Bu uygulama ortam başına **beş PostgreSQL veritabanı** kullanır — `primary`, `cache`, `queue`, `cable` ve `telemetry` (bkz. `config/database.yml`). Gerekirse oradaki bilgileri düzenleyin, ardından:

```bash
bin/rails db:create db:schema:load
bin/rails db:seed
```

`db:seed`, kanonik yetenek havuzunu (`db/seeds/canonical_skills.rb`) ve diğer seed verilerini yükler.

### 3. Uygulamayı çalıştırın
```bash
bin/dev
```

Arka plan işleri (Solid Queue) için Linux/macOS/production'da `bin/jobs` kullanın. Yerel Windows'ta `bin/jobs` Supervisor'ı `Process.fork`/`SIGQUIT`'e dayanır ve bunlar desteklenmez — bunun yerine yalnızca Windows için olan geliştirme worker'ını kullanın:

```bash
bin/dev_worker
```

---

## Test

Proje, `test/` altında modelleri, controller'ları, işleri, servisleri, kanalları (`terminal_chat_channel` dahil) ve sistem akışlarını (dashboard ızgara/DM dock davranışı, sohbet arayüzü, post akışı, profil ızgarası, tema menüsü ve daha fazlası) kapsayan kapsamlı bir test paketine sahiptir. Bu yazı itibarıyla: **612 unit/model/controller/job/service/channel testi** (2.085 assertion) ve **21 Capybara/Selenium sistem testi** (174 assertion), hepsi geçiyor.

```bash
bin/rails test          # unit/integration testleri
bin/rails test:system   # Capybara/Selenium sistem testleri
bin/rubocop              # stil lint (.rubocop.yml içinde rubocop-rails-omakase)
bin/brakeman             # statik güvenlik analizi
bin/bundler-audit        # bağımlılık zafiyet taraması
```

CI (`.github/workflows/ci.yml`), `main`/`master` dalına her push/PR'da Brakeman, bundler-audit, `bin/importmap audit`, RuboCop, test paketi ve sistem testi paketini (`pgvector/pgvector` Postgres servis konteynerine karşı) çalıştırır.

---

👨‍💻 Geliştirici: **Ayberk Arda**

Yazılım Geliştirici | Bilgisayar Programcılığı, İstanbul Kültür Üniversitesi (İKÜ)
