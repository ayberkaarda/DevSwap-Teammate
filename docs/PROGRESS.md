# PROGRESS

Bu dosya oturum başında okunmalı (bkz. CLAUDE.md). Her DUR-raporla noktasından sonra "Son durum" bölümü güncellenir.

## Son durum


Faz 11 ve Faz 12 tamamlandı. Faz 11 (Opus solo): gerçek kullanıcı testinde (canlı tarayıcı + gerçek GitHub girişi) bulunan 3 bug düzeltildi. Faz 12 (Sonnet + Opus, çok turlu): root/admin rolü + kişi bazlı audit log + telemetri sayfası fonksiyonelleştirildi, ardından mimari inceleme (`docs/architecture-review.md` §2) ışığında iki gerçek sorun bulunup düzeltildi: veri duplikasyonu ve senkron/tekil-DB telemetry yazımı. Tam test suite 112 runs / 346 assertions / 0 failures, rubocop 120 dosya temiz.

Faz 9 ve Faz 10 tamamlandı (Faz 9: Sonnet solo; Faz 10: Opus solo, backend+ActionCable+JS+view sıkı bağlı olduğu için tek agent'a verildi). Migration'lar development'ta uygulandı, tam test suite 90 runs / 255 assertions / 0 failures, rubocop 103 dosya temiz.

Faz 8 tamamlandı: continuous_type→direction rename (önce, tek başına) → PWA aktivasyonu + bildirim sistemi (Opus) ‖ terminal chat cilası + erişilebilirlik + test altyapısı borçları (Sonnet, paralel). Commit atılmadı, kullanıcı kendi commit'liyor.

Faz 8 kapsamı:
- **Rename** — `user_skills.continuous_type` kolonu `direction` olarak yeniden adlandırıldı (değerler aynı: `"teaching"`/`"learning"`). 18 dosyada (models, controllers, jobs, services, views, testler, fixture) referans güncellendi. Bu rename diğer her şeyin önkoşuluydu, bu yüzden tek başına ve önce çalıştırıldı.
- **PWA aktivasyonu** — Scaffold vardı ama routes.rb'de hiç route'lanmamıştı, `application.html.erb`'deki manifest linki yorum satırıydı. Artık gerçek: `rails/pwa#manifest`/`service_worker` route'ları, düzeltilmiş manifest (tema rengi, açıklama, ikonlar), gerçek bir minimal service worker (install'da temel asset cache, navigation request'lerde network-first + offline fallback), kayıt script'i. Aynı `application.html.erb` düzenlemesiyle bir skip-link de eklendi (erişilebilirlik borcu).
- **Bildirim sistemi** — `match_calculation_job.rb` artık gerçek bir işlev görüyor (önceden `sleep(2)` + log'dan ibaret bir stub'dı): bir Post yayınlanınca içeriğinde geçen skill isimlerini (word-boundary regex ile, kısa isimlerin —"Go", "R"— yanlış eşleşmesini önleyerek) tespit edip, o skill'e sahip (teaching veya learning) kullanıcılara (post sahibi hariç) bildirim gönderiyor. Yeni `post_notifications` tablosu + `NotificationsController` (`dismiss`, `claim`) + dashboard'daki zil (`notifications/_bell` partial). `claim` edilince aynı post'a ait TÜM DİĞER aktif bildirimler otomatik dismiss ediliyor (cascade — "biri ilgilenince diğerlerinden kaybolsun" davranışı).
- **Terminal chat cilası** — Komut geçmişi (yukarı/aşağı ok ile önceki komutlar/mesajlar), `/help` komutu (mevcut `/clear`/`/whoami`/`/ping`/`/omni` listesini gösterir), `/omni` artık gerçek kişisel durum paneli (teaching/learning skill sayısı, GitHub bağlantı durumu, teach/learn vektör varlığı — bir `omni-stats` meta tag'i üzerinden sunucudan JS'e taşınıyor). Bonus: `current-user` meta tag'inin hiç render edilmediği, JS'in her zaman hardcoded "Ayberk" fallback'ine düştüğü gerçek bir bug bulundu ve düzeltildi.
- **Erişilebilirlik** — Skip-link (yukarıda, PWA ile birlikte), chat mesaj akışına (`#chat-messages`, `#typing-indicator`) `aria-live="polite"` bölgeleri.
- **Profil aktivite grafiği** — `profiles/show.html.erb`'de teaching skill'lerin `weight` değerlerine göre CSS tabanlı bar chart (yeni kütüphane eklenmeden, mevcut eşleşme-skoru bar deseni yeniden kullanılarak).
- **Test paralelleştirme deadlock'u kalıcı çözüldü** — `test/test_helper.rb`'deki `parallelize` artık `workers: 1`; `PARALLEL_WORKERS=1` env var'ına ihtiyaç kalmadı, `bin/rails test` doğrudan güvenli.
- **`test/channels/terminal_chat_channel_test.rb`** artık gerçek testler içeriyor (boş iskelet değil).
- **README.md** güncellendi (Faz 6/7/8 sonrası mimari, kurulum notları).

Son doğrulama: `bin/rails test` → 70 runs, 189 assertions, 1 failures (sadece 7.1'in bilinçli-kırmızı Node.js/NodeJS testi), `bin/rubocop` → 91 dosya, temiz.

Faz 7 tamamlandı: 7.1 (kanonik skill sözlüğü) → 7.2 (learning nudge + checkbox grid) → 7.4 (herkese açık profil + repo verisi) → 7.3 (GitHub tarama bilgi kartı). Commit sırası (en eskiden en yeniye):

Faz 7 tamamlandı: 7.1 (kanonik skill sözlüğü) → 7.2 (learning nudge + checkbox grid) → 7.4 (herkese açık profil + repo verisi) → 7.3 (GitHub tarama bilgi kartı). Commit atılmadı, kullanıcı kendi commit'liyor.

Faz 7 kapsamı:
- **7.1** — `db/seeds/canonical_skills.rb`: GitHub Linguist dil isimleriyle birebir eşleşen ~50 dil + ~20 framework/araçtan oluşan idempotent bir kanonik skill havuzu. Learning dropdown'unun GitHub taramasıyla AYNI `Skill` satırlarından beslenmesini sağlıyor. `match_finder_test.rb`'ye, isim normalizasyonu farkının ("Node.js" vs "NodeJS") eşleşmeyi bozduğunu KANITLAYAN, bilinçli olarak kırmızı bırakılan bir regresyon testi eklendi.
- **7.2** — `profiles/edit.html.erb`'deki learning kartı artık kategoriye göre gruplu (Diller/Framework/Araçlar), client-side filtrelenebilir bir checkbox grid; `UserSkillsController#create` çoklu `skill_ids` kabul ediyor (tek `insert_all`, tek embedding job). Dashboard'da learning listesi boşsa görünen bir nudge banner'ı eklendi.
- **7.4** — `github_repositories` tablosu (migration + model), `GithubScanJob` artık repo listesini (ad, açıklama, dil, yıldız, URL) ek API çağrısı yapmadan DB'ye `upsert_all` ile yazıyor (dil tespit edilemese bile). Yeni `profiles#show` (`GET /u/:id`, route helper `public_profile_path` — mevcut `profile_path`/`edit_profile_path` ile çakışmaması için özel isimlendirildi) herkese açık, salt-okunur bir profil sayfası: teaching/learning listesi, viewer-relative eşleşme skoru/nedeni/karşılıklılık rozeti (`MatchFinder` yeniden kullanılıyor), GitHub repo kartları. Dashboard'daki eşleşme/arama kartları artık profile linkli.
- **7.3** — Dashboard'da, `source: "github"` olan `user_skills` varsa görünen pasif bir bilgi kartı ("GITHUB_SCAN.detected()") — son tarama zamanı + tespit edilen diller + ağırlık yüzdesi, profil düzenlemeye link. Gerçek bir onay/red akışı değil (skill'ler zaten otomatik ekleniyor), sadece şeffaflık.


Faz 6 tamamlandı: 6.1 (test altyapısı) → 6.2 (pgvector aktivasyonu) → 6.3 (skor/neden/reciprocal). Commit sırası (en eskiden en yeniye):


```
b0b9ef6  test: model testleri ve gercek fixture verisi ekle
dee92c3  test: UserEmbeddingBuilder icin determinizm ve mevcut davranis testleri
6392129  test: GenerateUserEmbeddingJob uc korumasi icin regresyon testleri
456cc3f  docs: mimari inceleme raporundan ilgili alintilari ekle
7fa9dc1  db: user_skill_vectors icin embedding_teach/embedding_learn kolonlarina bol
cc79727  refactor: UserEmbeddingBuilder ve embedding job'u teach/learn'e bol
14d5d84  feat: pgvector tabanli capraz teach/learn eslestirmesini devreye al
f8a0be1  fix: son skill silinince stale embedding kaydini temizle
5136779  test: sifir-vektor yerine nil kaydedildigine dair regresyon testi
3ba2bfb  feat: MatchFinder skor/karsilikli/eslesme nedeni verisini disa acar
d1b82e2  feat: dashboard'da kalite bar'i, eslesme nedeni ve reciprocal rozeti
```



### Faz 11 — Gerçek kullanıcı testinde bulunan 3 bug

Canlı tarayıcı + gerçek GitHub girişiyle yapılan kabul testinde 3 gerçek regresyon bulundu, kök nedenleri tespit edilip düzeltildi:

- **`/u/:id` bazen 500 veriyordu** — `MatchFinder.call`, viewer'ın embedding vektörü yoksa `MatchFinder::Match` yerine düz `User` döndürüyordu (`fallback_candidates`), ama `profiles/show.html.erb` koşulsuz `@match.reciprocal`/`.reason`/`.score` çağırıyordu. Fix: view koşulu `@match.is_a?(MatchFinder::Match)` oldu. Regresyon testi eklendi.
- **Slash komutları oda değiştirince ölüyordu** — Faz 10'un Turbo Frame tabanlı oda geçişi, `#terminal-form`'un DOM'unu her seferinde yok edip yeniden oluşturuyordu; event listener'lar elementlere bağlıydı, DOM yenilenince kayboluyordu. Fix: `terminal_chat_channel.js`'deki keydown/submit/input handler'ları `document`'a bağlanan event delegation desenine çevrildi — artık DOM kaç kez yenilenirse yenilensin çalışıyor.
- **Aktif oda sekmesi göstergesi güncellenmiyordu** — sekme çubuğu `turbo_frame_tag "chat_panel"`'in DIŞINDaydı, oda değişince yeniden render edilmiyordu. Fix: sekme çubuğu yeni bir partial'a (`dashboard/_room_tabs`) çıkarılıp frame'in İÇİNE taşındı; artık her oda geçişinde sunucudan taze render ediliyor.

### Faz 12 — Root/admin rolü + audit log + telemetri (çok turlu)

**İlk tur (Sonnet):** `User#admin?`, `ActivityLog` modeli, login/logout/skill-ekleme/skill-silme/mesaj-gönderme'de loglama, telemetri sayfasına admin-only kullanıcı seçici + log tablosu.

**Mimari inceleme turu:** Kullanıcı, `docs/architecture-review.md` §2'yi (Veritabanı İzolasyonu — beşinci mantıksal DB, partitioning, senkron yazma yasağı) referans alarak ilk turun uygulamasını sorguladı. Doğrulanan gerçek sorunlar:
- `ActivityLog.record!` senkron `create!` yapıyordu, request döngüsü içinde — özellikle `MessagesController#create`'de her mesajda bir INSERT.
- `activity_logs` ve `telemetry_snapshots` hâlâ primary DB'deydi, beşinci mantıksal DB (`telemetry:`) hiç kurulmamıştı (Faz 4'ün tamamlanmamış maddesi — yeniden doğrulandı).
- Partitioning/retention yoktu, `activity_logs` sonsuza dek büyüyecekti.
- Negatif yetkilendirme testleri (admin olmayan + `user_id` param manipülasyonu, anonim erişim, role mass-assignment) eksikti — pozitif testler yetersizdi.

**Düzeltme turları (sırayla):**
1. **Negatif testler** — non-admin + `?user_id=X` → hedef kullanıcının logu sızmıyor (kanıtlandı); anonim `/telemetry` → `root_path`'e yönlendiriliyor; `PATCH /profile` ile `role: "admin"` göndermek işe yaramıyor (mass-assignment güvenli, kanıtlandı).
2. **Duplikasyon kesme** — `message_sent`/`skill_added`/`skill_removed` loglaması `ActivityLog`'dan tamamen kaldırıldı (bu veri zaten `messages`/`user_skills` tablolarında duruyordu). Yeni `UserActivityTimeline` servisi, `activity_logs` (login/logout) + `messages` + `user_skills`'i tek kronolojik listede birleştirip admin görünümüne sunuyor. **Bilinen kapsam kaybı:** `skill_removed` olayları artık hiçbir yerde izlenmiyor — bir yetenek kaldırıldığında bu olayın geçmişi kalıcı olarak kayboluyor (kullanıcı onayıyla kabul edildi).
3. **Beşinci `telemetry:` DB + native partitioning + async yazım** — `config/database.yml`'e `telemetry:` bloğu eklendi (primary/cache/queue/cable deseniyle tutarlı). `activity_logs` ve `telemetry_snapshots` primary'den düşürülüp `telemetry:` DB'sinde native PostgreSQL RANGE partitioning (aylık, composite PK) ile yeniden kuruldu. `TelemetryPartitionMaintenanceJob` (günde bir, `config/recurring.yml`) 3 ay ileri partition açıyor, 12 aydan eski partition'ları `DROP TABLE` ile düşürüyor (DELETE değil — vacuum güvenli). Kısa bir süre `TelemetryTickJob`'daki eski `TelemetrySnapshot.where("captured_at < ?", 10.minutes.ago).delete_all` satırı unutulmuş kaldı — bu, partitioning'in amacını (DROP PARTITION ile ucuz retention) fiilen boşa çıkarıyordu, çünkü veri hiç 10 dakikayı geçip bir partition'ı doldurmaya fırsat bulamıyordu. Gerçek veriyle doğrulandı (worker ilk kez çalıştıktan sonra: 10 kayıt, hepsi son 9 dakika içinde, 10 dakikadan eski sıfır kayıt) ve satır kaldırıldı — `telemetry_snapshots` artık gerçekten 12 aylık tarihsel bir tablo, kayan pencere değil. Dashboard okuması (`TelemetrySnapshot.history(60)`, BRIN index sayesinde) tablo boyutundan bağımsız çalışmaya devam ediyor, değişiklik gerekmedi. `ActivityLog.record!` kısa süre async (`ActivityLogWriteJob.perform_later`) yapıldı, ama Windows dev ortamında Solid Queue worker'ları hiç çalışmadığı (ayrı bir bulgu, aşağıya bak) fark edilince bu yarım soyutlama SENKRON `create!`'e geri alındı — job dosyası tamamen silindi. Gerekçe: buffer/batch altyapısı (Solid Cache + periyodik flush, TelemetryTickJob deseni) kurmak bugünün gerçek hacmi (birkaç kullanıcı) için spekülatif karmaşıklık; 10K CCU bir hedef varsayımıydı, bugünün verisi değil. **Bilinen mimari gerçek:** `activity_logs.user_id` artık `users`'a DB-seviyesinde FK ile bağlı değil (Postgres cross-database FK desteklemiyor) — referans bütünlüğü sadece uygulama seviyesinde. Bağlantı havuzu aritmetiği güncellendi: 20 süreç × 5 DB × 5 bağlantı = 500 (önceki 400'den %25 artış), `docs/architecture-review.md`'deki "Üçüncü (sinsi) darboğaz" bölümüne işlendi.

Son doğrulama: `bin/rails test` → 112 runs, 346 assertions, 0 failures. `bin/rubocop` → 120 dosya, temiz.

### Faz 9 — Kanonik skill alias tablosu

`UserEmbeddingBuilder#bucket_for` skill isimlerini ham haliyle MD5 hash'liyordu, bu yüzden "Node.js" ve "NodeJS" gibi aynı kavramın farklı yazım varyantları ayrı `Skill` kayıtları olarak birikiyordu (veri gereksiz parçalanıyordu). Kök neden yazma (write) noktalarında çözüldü:

- Yeni `skill_aliases` tablosu + `SkillAlias` modeli: normalize edilmiş isim (`downcase.strip.delete(" .")` — `match_finder.rb`'deki mevcut normalizasyonla birebir aynı) → kanonik `Skill` eşlemesi.
- Yeni `SkillResolver` servisi: bilinen bir varyant geldiğinde var olan kanonik Skill'i döndürüyor, bilinmeyen isimlerde yeni Skill + alias kaydı oluşturuyor. `github_scan_job.rb` ve `user_skills_controller.rb` artık `Skill.find_or_create_by` yerine bunu kullanıyor.
- `db/seeds/skill_aliases.rb`: bilinen varyant haritası (Node.js/NodeJS/Node, JavaScript/JS, TypeScript/TS, PostgreSQL/Postgres/psql, C++/Cpp, C#/CSharp, .NET/Dotnet, Ruby on Rails/Rails/RoR, Kubernetes/K8s, CI/CD).
- `match_finder_test.rb`'deki eskiden "bilinçli kırmızı" olan Node.js/NodeJS testi artık gerçekten yeşil geçiyor ve yorumu güncellendi: `match_finder.rb`'nin var olan (legacy) duplicate kayıtları normalize ederek tolere ettiğini, `SkillResolver`'ın ise yeni duplicate oluşumunu yazma anında engellediğini kanıtlayan bir regresyon testi haline geldi.

### Faz 10 — Sekmeli çoklu terminal chat odası

Tek global chat kanalı çoklu `ChatRoom`'a bölündü, Turbo Frame ile tam sayfa yenilemeden oda geçişi:

- Yeni `chat_rooms` tablosu + `ChatRoom` modeli (`name`, `slug`, `position`); `messages.chat_room_id` eklendi (migration mevcut mesajları otomatik "genel" odasına bağlayıp NOT NULL yapıyor).
- `TerminalChatChannel` artık oda-özel stream'e abone oluyor (`terminal_chat_channel_#{room_slug}`), `typing` action'ı da oda-bazlı debounce/broadcast yapıyor. `Message#broadcast_to_terminal_chat` da aynı şekilde oda-özel kanala yayın yapıyor.
- Yeni `RoomsController#show` (`/rooms/:slug`) — chat panelini (`dashboard/_chat_panel` partial, yeni çıkarıldı) `chat_panel` turbo frame içinde oda bazlı render ediyor.
- `dashboard/index.html.erb`'ye sekme çubuğu eklendi (`role="tablist"`, her sekme `data-turbo-frame="chat_panel"` ile sadece frame'i değiştiriyor).
- `terminal_chat_channel.js`: ActionCable subscription artık `subscribeToRoom(roomSlug)` factory'sine çevrildi, `turbo:frame-load` (`chat_panel` frame'i için) eski subscription'dan çıkıp yeni odaya abone oluyor. Komut geçmişi/`/omni`/sessionStorage mantığına dokunulmadı.
- Odalar: genel/backend/frontend/kariyer (`db/seeds/chat_rooms.rb`, idempotent).
- Önceki debt notu ("önce Solid Cable ölçeklenme testi yapılmalı") kullanıcı onayıyla kapatıldı: gerçek 10K CCU yük testi bu ortamda yapılamadığı için, karar prod-öncesi ayrı bir doğrulama maddesi olarak "Bilinen borçlar"a taşındı (aşağıya bak), kod tarafında engel sayılmadı.

## Kritik gerçek (Faz 7 öncesi tespit, düzeltilmiş — tarihsel referans)

> Önceki "6 kullanıcıdan sadece 1'inde vektör var" tespiti dev DB'nin doğrudan sorgulanmasıyla yeniden doğrulandı: 6 kullanıcıdan 5'i organik değildi (2 demo seed + 3 test/telemetry/ui-verification hesabı). Tek gerçek GitHub-login hesabı teaching vektörüne sahipti, learning'e değil — tam beklenen yapısal boşluk. Faz 7 (7.1+7.2) bunu doğrudan hedefledi, Faz 8'in bildirim sistemi ve terminal cilası ise veri toplandıktan sonraki keşfedilebilirlik/etkileşim katmanını tamamladı.

## Bilinen borçlar

- `PostNotification` oluşturulurken bir aday kullanıcının post içeriğiyle eşleşen BİRDEN FAZLA skill'i varsa sadece ilk eşleşen skill kaydediliyor (bildirim metninde tek skill gösteriliyor) — kasıtlı basitleştirme, birden fazla post_notification satırı yerine tek satır tercih edildi.
- Terminal chat komut geçmişi (yukarı/aşağı ok) artık sessionStorage ile sayfa yenilenmesinde kalıcı (ayrı bir bugfix'te eklendi).
- Faz 10 ile devreye giren çoklu-oda ActionCable mimarisi, gerçek üretim (production) trafiğinde CCU/Solid Cable ölçeklenme testinden GEÇMEDİ — bu ortamda gerçek yük testi yapılamadığı için kullanıcı onayıyla kod tarafında engel sayılmadan devreye alındı. Prod'a çıkmadan önce gerçek bir yük testi (ör. çok sayıda eşzamanlı WebSocket bağlantısı) yapılmalı.
  - **Bilinen risk (mimari rapor referansı, `docs/architecture-review.md` §1):** Faz 10 (oda-bazlı stream'ler) mimari rapor §1.2'nin gerektirdiği 10K CCU önkoşulunu karşılar — global stream O(N²) sorunu çözüldü. Ölçülmemiş kalan: oda sayısı arttıkça Solid Cable'ın poll churn'ü (stream sayısı × Puma süreci × polling_interval). İlk gerçek yük öncesi solid_cable_messages tablosunun INSERT/DELETE hacmi ve autovacuum gecikmesi izlenmeli. Mevcut ayar: polling_interval 0.3s, message_retention 1h (Faz 5.1, bkz. `config/cable.yml`). Bkz. `docs/DEPLOY_CHECKLIST.md`.
- `skill_removed` olayları hiçbir yerde izlenmiyor (Faz 12'nin duplikasyon-kesme kararının bilinçli sonucu, yukarıda detaylı açıklandı) — bir yetenek kaldırıldığında bu olayın geçmişi kalıcı olarak kayboluyor.
- `activity_logs.user_id` artık gerçek bir DB-seviyesi foreign key ile korunmuyor (beşinci `telemetry:` DB'ye taşındığı için, Postgres cross-database FK desteklemiyor) — referans bütünlüğü sadece uygulama seviyesinde.
- **`GithubScanJob` gerçek, önceden var olan bir bug ile başarısız oluyor** (bugünkü kapsamda bulundu, bugünkü işle ilgisi yok, düzeltilmedi): `app/jobs/github_scan_job.rb:18` — `client.repos(user.github_username, { type: "owner", sort: "updated" }, headers: headers)` çağrısı `ArgumentError: wrong number of arguments (given 3, expected 0..2)` ile patlıyor. Kök neden muhtemelen Octokit gem versiyonu (9.2.0) ile bu çağrının imzası arasındaki uyumsuzluk — `repos`/`repositories` metodu artık `headers` için ayrı bir 3. pozisyonel/kwarg argüman kabul etmiyor olabilir, `options` hash'ine gömülmesi gerekiyor olabilir. GitHub taraması şu an HİÇBİR kullanıcı için çalışmıyor demektir — gerçek bir prod-blocker, ayrı bir fazda ele alınmalı.
- **Tetikleyicili borç — ActivityLog senkron yazımı:** Gerçek günlük login/logout hacmi 1000'i geçtiğinde, `ActivityLog.record!` TelemetryTickJob desenindeki Solid Cache buffer + dakikalık `insert_all` flush yaklaşımına geçirilmeli (request döngüsünü korumak için). Buffer kayıp penceresi (≤1 dakika, sunucu çökerse o pencerenin login/logout kayıtları kaybolur) o noktada tekrar değerlendirilecek — audit log bağlamında (finansal/güvenlik-kritik değil) kabul edilebilir bulundu, ama karar hacim eşiğine bağlı, şimdiden kurulmadı.
- **Windows dev ortamında Solid Queue'nun standart çalıştırma yolları (`bin/jobs` Supervisor, Puma `plugin :solid_queue`) çalışmıyordu** — `Process.fork`/`SIGQUIT` native Windows Ruby'de desteksiz (doğrulandı, gerçek hatalarla). Bu, oturum boyunca ~86+ async job'un (GithubScanJob, GenerateUserEmbeddingJob, TelemetryTickJob, MatchCalculationJob dahil) hiç işlenmediği anlamına geliyordu. Çözüldü: `bin/dev_worker` (Supervisor'sız, Worker+Dispatcher+Scheduler'ı thread olarak çalıştıran, sadece dev için bir script) + `config/recurring.yml`'e `development:` bloğu eklendi (öncesinde sadece `production:` vardı, dev'de hiç recurring task parse edilmiyordu).

## Sıradaki aday fazlar

- Faz 13 (aday) — Kurallar onayı akışı (giriş sonrası zorunlu okuma/onay) + root'un GitHub hesabı bazlı manuel ban sistemi (süreli, açıklamalı, aç/kapa). Otomatik ihlal tespiti YOK (kullanıcı kararı) — sadece root manuel banlıyor.
- Faz 14 (aday) — Eşleşme sağlanan kullanıcılar arasında özel 1:1 sohbet odası (mevcut oda-bazlı yayın mimarisinin üzerine, katılımcıya özel erişim kontrolü gerekiyor).
- Faz 15 (aday) — Profildeki "öğretebileceklerim/öğrenmek istediklerim" alanının genişletilmesi — kapsam netleştirilmedi, kullanıcıdan detay bekleniyor.

## Kritik gerçek

## Kritik gerçek (düzeltilmiş)


> **Faz 7 öncesi durum, DÜZELTİLDİ:** Önceki "6 kullanıcıdan sadece 1'inde vektör var" tespiti dev DB'nin doğrudan sorgulanmasıyla YENİDEN doğrulandı: 6 kullanıcıdan 5'i organik değil — `db/seeds.rb`'deki 2 demo kullanıcı ve önceki oturumlardan kalma 3 test/telemetry/ui-verification hesabı. Tek GERÇEK GitHub-login hesabı, tam da beklendiği gibi teaching vektörüne sahipti, learning vektörüne değil. Yani rakam bir ürün sorunu değil dev-DB artifact'ıydı — ama altta yatan YAPISAL bulgu (learning tarafını dolduran hiçbir otomasyon yoktu, sadece manuel dropdown) gerçekti ve Faz 7 (özellikle 7.1 + 7.2) bunu doğrudan hedefledi. Üretimde gerçek kullanıcı verisiyle veri toplama darboğazının çözülüp çözülmediği hâlâ gözlemlenmeli.

## Bilinen borçlar

- `continuous_type` kolon adı yanıltıcı (aslında "teaching"/"learning" rolünü tutuyor, "continuous" kelimesi anlam ifade etmiyor) — rename bir migration gerektirir, henüz yapılmadı.
- PWA scaffold (`app/views/pwa/manifest.json.erb`, `service-worker.js`) repoda var ama gerçek bir PWA stratejisi/karar yok — kullanılacak mı, kaldırılacak mı belirsiz.
- README güncel değil (Faz 6 sonrası mimari/kurulum bilgisini yansıtmıyor).
- `test/channels/terminal_chat_channel_test.rb` boş/iskelet halde — gerçek bir test içermiyor.
- Sekmeli çoklu oda (terminal chat için birden fazla kanal/oda) özelliği ertelendi — gerekçe: 10K eşzamanlı kullanıcı (CCU) senaryosunda Solid Cable/Action Cable ölçeklenme riski, önce mevcut tek-oda modelin sağlamlığı kanıtlanmalı.
- `/omni` komutu (muhtemelen terminal chat'te bahsi geçen bir komut) net tanımlanmamış/belirsiz durumda.
- **Kanonik skill kanonikleştirmesi tam değil** (Faz 7.1'den kalan, bilinçli kapsam dışı): `UserEmbeddingBuilder#bucket_for` hâlâ skill adını ham haliyle (downcase+strip sonrası) MD5 hash'liyor, alias/eş anlamlı tablo yok. 7.1 sadece learning dropdown'unu GitHub'ın kullandığı isimlerle ÖNCEDEN doldurarak riski azalttı, kökten çözmedi. `match_finder_test.rb`'deki Node.js/NodeJS testi bunu bilinçli olarak kırmızı tutarak belgeliyor. Gerçek çözüm: alias/kanonikleştirme tablosu (L efor).
- **Test paralelleştirme eşiği Postgres deadlock'una giriyor** (Faz 7 sırasında keşfedildi): `test/test_helper.rb`'deki `parallelize(workers: :number_of_processors, with: :threads)` ayarı, proje 50 testi aşınca (şu an ~53 test) devreye giriyor; birden fazla paralel worker'ın aynı anda Postgres fixture'larını FK-doğrulamasıyla (`check_all_foreign_keys_valid!`) yüklemesi zaman zaman `PG::TRDeadlockDetected` ile sonuçlanıyor. Geçici çözüm: `PARALLEL_WORKERS=1 bin/rails test` ile paralelliği kapatmak. Kalıcı çözüm henüz yapılmadı (ya `parallelize` ayarını kaldırmak/threshold'u yükseltmek ya da fixture yükleme stratejisini değiştirmek gerekebilir).
- `match_calculation_job.rb` ölü kod DEĞİL — `Post` modeli (`after_create_commit`) tarafından gerçekten tetikleniyor ve bir test bunu doğruluyor, ama içeriği stub (`sleep 2` + iki log satırı), gerçek bir hesaplama yapmıyor. Ne yapılacağı (gerçek işleve bağlanacak mı, olduğu gibi mi kalacak) henüz kararlaştırılmadı.

## Sıradaki aday fazlar

- Faz 8 — Cila: komut geçmişi (terminal chat'te yukarı ok ile önceki komutlar), `/help` komutu, `aria-live` bölgeleri (erişilebilirlik), skip-link (klavye kullanıcıları için), profil sayfasında yetenek/aktivite grafiği.



- Faz 9 (aday) — Yukarıdaki borçlardan önceliklendirme: test paralelleştirme deadlock'u ve kanonik skill alias tablosu, üretim öncesi ele alınmalı.

