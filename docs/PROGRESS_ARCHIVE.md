# PROGRESS_ARCHIVE

Bu dosya PROGRESS.md'in eski (arşivlenmiş) fazlarının tam, kısaltılmamış içeriğini barındırır — güncel özet ve en yeni fazlar için docs/PROGRESS.md dosyasına bakın.

Faz 31 (a-e, Dashboard kapsamlı yeniden tasarımı) tamamlandı — `gelistirme-prompt.md` madde 10'un tamamı devreye alındı. Tam test suite 277 runs / 877 assertions / 0 failures (Faz 31 öncesi baseline 256'dan büyüdü), `bin/rails test:system` 5 runs / 28 assertions / 0 failures, rubocop temiz.

Faz 29 (Sonnet) ve Faz 30 (Opus) tamamlandı, paralel çalıştı — `gelistirme-prompt.md`'nin Faz 21'den beri süren uygulaması Faz 30 ile Faz 31'e (dashboard kapsamlı yeniden tasarımı) kadar duruyordu, Faz 31 ayrı planlanıp ardından tamamlandı (yukarı bakınız). Tam test suite 256 runs / 820 assertions / 0 failures, rubocop 172 dosya temiz.

Faz 27 (Opus) ve Faz 28 (Sonnet) tamamlandı, paralel çalıştı. Tam test suite 248 runs / 777 assertions / 0 failures, rubocop 171 dosya temiz.

Faz 25 (Opus) ve Faz 26 (Sonnet) tamamlandı, paralel çalıştı. Tam test suite 243 runs / 755 assertions / 0 failures, rubocop 168 dosya temiz. Kanonik skill/tag havuzu 113'e çıktı.

Faz 23 (Opus) ve Faz 24 (Sonnet) tamamlandı, paralel çalıştı. Tam test suite 238 runs / 727 assertions / 0 failures, rubocop 168 dosya temiz.

Kullanıcı `gelistirme-prompt.md` adında yeni, kapsamlı bir geliştirme görev listesi ekledi (16 ana madde, 2 liste). Bu liste Faz 21'den itibaren sırayla, Opus+Sonnet paralel çalışmasıyla uygulanıyor. Faz 21 (Opus) ve Faz 22 (Sonnet) tamamlandı. Tam test suite 225 runs / 690 assertions / 0 failures, rubocop 163 dosya temiz. **Not:** proje artık `db/schema.rb` yerine `db/structure.sql` kullanıyor (`config.active_record.schema_format = :sql`, kullanıcı tarafında committed edilmiş harici bir değişiklik — muhtemelen native partitioning'in schema.rb'de tam temsil edilememesi yüzünden) — bundan sonraki doğrulamalarda `db/structure.sql` referans alınacak.

Faz 15, 20, 16 ve 17 tamamlandı (sırayla: Faz 15 paralel Opus+Sonnet, Faz 20 paralel Opus+Sonnet, Faz 16 Sonnet + Faz 17 Opus paralel). Faz 15: profil skill alanları genişletildi (yeterlilik seviyesi, not+kanıt linki, öğretim tercihi) + kanonik havuz 99 yeteneğe çıktı. Faz 20: DM ilişkisi karşılıklı sonlandırılabiliyor, gizli değerlendirme/puanlama sistemi kuruldu, arama çoklu-terim + puan bazlı sıralandı. Faz 16: blog-tarzı etiketli post sistemi. Faz 17: moderatör rolü + uyarı/mute/eskalasyon + kullanıcı şikayet sistemi (böylece ayrı planlanan "Faz 18 şikayet sistemi" Faz 17'ye dahil edilerek tamamlandı, ayrıca yapılmayacak). Tam test suite 218 runs / 672 assertions / 0 failures, rubocop 160 dosya temiz. Tüm migration'lar development'ta uygulandı.

Faz 13 ve Faz 14 tamamlandı, PARALEL geliştirildi (Faz 13: Sonnet, Faz 14: Opus — dosya sahipliği net ayrıldı, `config/routes.rb`'de iki farklı anchor noktası kullanıldı, çakışma olmadı). Faz 13: kurallar onayı akışı + GitHub hesabı bazlı manuel ban sistemi. Faz 14: eşleşme sonrası özel 1:1 DM sohbet odaları, ActionCable session-tabanlı yetkilendirme ile. Tam test suite 147 runs / 444 assertions / 0 failures, rubocop 128 dosya temiz. Migration'lar development'ta uygulandı.

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

### Faz 31 (a–e) — Dashboard kapsamlı yeniden tasarımı: TAMAMLANDI

`gelistirme-prompt.md` madde 10, 5 alt-fazda sırayla uygulandı:

- **31a** — Nav'a "Dashboard" (`root_path`) ve "Yapabileceklerim" (yeni `guide_controller`/`guide#show`, `/guide` route) linkleri eklendi; `dashboard/index` ve `profiles/edit`'teki redundant "Kontrol Kulesi"/"Dashboard'a Dön" linkleri kaldırıldı.
- **31b** — `DashboardWidget` modeli eklendi (migration `20260718180000_create_dashboard_widgets.rb`) — `widget_type` (12 sabit tür), `position_x/y`, `width/height`, `font_scale` (0.5-2.0), `visible`; `[user_id, widget_type]` üzerinde DB-level unique index. `DashboardWidget.seed_defaults_for(user)` ile ilk ziyarette lazy varsayılan 12 widget oluşturuluyor (`DashboardController#index`'te idempotent guard ile). Persistence API: `PATCH /dashboard_widgets/reorder` (Gridstack toplu layout kaydı, sahiplenme kontrollü, 200/422) ve `PATCH /dashboard_widgets/:id` (font_scale/visible toggle).
- **31c** — Gridstack.js `bin/importmap pin gridstack` ile bağlandı (CDN, build-step yok — projenin "sıfır harici JS bağımlılığı" disiplininden bilinçli sapma). Yeni Stimulus controller `dashboard_grid_controller.js`: grid varsayılan kilitli, "Düzenle" butonuyla drag/resize açılıyor, değişiklikler `reorder` endpoint'ine batch POST ediliyor. Mevcut chatbox/match_algorithm/dev_feed içerikleri `app/views/dashboard/widgets/_*.html.erb` partial'larına taşındı (silindi, kopyalanmadı), diğer 9 tür için placeholder partial'lar oluşturuldu.
- **31d** — 9 placeholder widget'ın gerçek implementasyonu: hava durumu (browser geolocation + Open-Meteo API, `weather_controller.js`), son etkileşimde olunan kullanıcılar (DM'lere göre, 2x2 sayfalanabilir, `recent_contacts_controller.js`), çevrimiçi kullanıcı sayısı (page-load snapshot, canlı değil — bilinen basitleştirme), DevSwap Activity (kozmetik placeholder, gerçek veri kapsam dışı — ayrı bir faza bırakıldı), hızlı eylemler, son postlar, bildirimler (mevcut `_bell` sorgusu widget'a taşındı, `_bell` partial'ı ayrıca yerinde kaldı), sistem saati (`clock_controller.js`), terminal komut kısayolları (sarı sticky-note tasarımı, gerçek `/clear /whoami /ping /omni /help` komutları, tıklanınca `#message_body`'ye yazıyor).
- **31e** — Minimal DM Modu: chatbox widget'ı gizlenince `_minimal_dm_bar.html.erb` (sabit alt-sol dock) gösteriliyor: ≤3 DM ise isim+okunmamış rozeti, >3 DM ise sadece avatar. Tıklanınca yukarı açılan popup, mevcut `rooms#show`'un `turbo_frame_tag "chat_panel"` altyapısını "frame promotion" ile yeniden kullanıyor (yeni endpoint YOK) — bu sayede mevcut ActionCable tabanlı canlı mesajlaşma JS'i (`#chat-messages`/`#terminal-form` id'lerine dayanan) hiç değiştirilmeden çalışıyor.

Son doğrulama: `bin/rails test` → 277 runs, 877 assertions, 0 failures (31a öncesi baseline 256'dan büyüdü: yeni guide/dashboard_widget/dashboard_widgets_controller testleri eklendi). `bin/rails test:system` → 5 runs, 28 assertions, 0 failures (`dashboard_grid_test.rb` + `minimal_dm_mode_test.rb` + mevcut `profile_with_real_embedding_test.rb` bir arada sorunsuz). `bin/rubocop` → temiz (yeni `.rb` dosyalarında offense yok).

### Faz 29 — Telemetri: DM içeriği görüntüleme

- Admin'in aktivite log'unda mesaj olayları artık DM (özel oda) ile genel oda mesajlarını ayırt ediyor (`dm_sent` vs `message_sent` action_type, DM'lerde "DM → {karşı taraf adı}" etiketi — önceden private odalar jenerik "Özel Mesaj" ismiyle gösteriliyordu, kime yazıldığı belli değildi).
- Admin, seçtiği kullanıcının DM yaptığı kişilerden birini seçip o ikili arasındaki TAM DM geçmişini kronolojik olarak görebiliyor (`dm_with_user_id` parametresi).
- **Doğrulanan (yeni bulunmayan, zaten var olan) davranış:** Bireysel değerlendirme/puanlama notları (Faz 20) admin'in aktivite log'unda ZATEN görünüyordu — bu tasarım gereği (Faz 20'nin kendi kararı), Faz 29 bunu DEĞİŞTİRMEDİ. Asıl korunan gizlilik kuralı (normal kullanıcılar — rater/rated_user dahil — birbirlerinin puanını hiç göremez) regresyon testiyle yeniden doğrulandı.

### Faz 30 — Telemetri canlı güncelleme + htop tarzı monitör

- **Doğrulanan (yeniden kurulmayan) altyapı:** Telemetri sayfası Faz 4'ten beri zaten Turbo Streams (ActionCable üzerinden) ile canlı güncelleniyordu (`turbo_stream_from "telemetry_dashboard"`, `TelemetryTickJob`'ın ~1sn'de bir broadcast'i) — bu YENİDEN YAPILMADI, üzerine inşa edildi.
- Yeni "SYSTEM_MONITOR" (htop tarzı) bölümü: Solid Queue job'larının durum dağılımı (ready/scheduled/claimed/failed) renkli çubuklarla, yaklaşık çevrimiçi kullanıcı sayısı, eşleştirme kuyruğu derinliği — koyu/yeşil terminal (matrix) estetiğiyle, hem ilk sayfa yüklemesinde hem canlı broadcast'te render ediliyor (`local_assigns[:htop].present?` guard'ı ile partial'ın çift kullanım yolunda kırılmaması sağlandı). DB şeması DEĞİŞMEDİ (migration yok) — bu veriler kaydedilmiyor, sadece anlık görüntü.
- **Dürüst sınırlama (kodda yorumla belirtildi):** "Aktif WebSocket bağlantı sayısı" Solid Cable'ın DB-backed mimarisi yüzünden doğrudan ölçülemiyor — `is_online` (Faz 21 presence tracking) yaklaşık bir vekil değer olarak kullanıldı, gerçek bağlantı sayısı DEĞİL.

Son doğrulama (Faz 29+30 birlikte): `bin/rails test` → 256 runs, 820 assertions, 0 failures. `bin/rubocop` → 172 dosya, temiz. Migration yok.

### Faz 27 — Chatroom geliştirmeleri

- 4 yeni oda: cloud, machine-learning, game-development, isletim-sistemi (toplam 8 oda).
- `chat_rooms.rules` (text) + her odanın konusuna uygun kısa kural metni. Oda paneline (`_chat_panel.html.erb`) yukarıdan kayarak inen (slide-down CSS animasyonu) kural banner'ı eklendi — panel zaten her oda değişiminde Turbo Frame ile tamamen yeniden render edildiği için (Faz 10/11 mimarisi) ekstra JS event wiring gerekmedi, banner her girişte otomatik animasyonla beliriyor.
- Eğlence: aynı kullanıcı art arda 3 mesaj atınca veya bir mesaj 200 karakterden uzun olunca, client-side (sunucuya hiçbir şey gitmeden) soluk bir `[SYS]: {user} is cooking 🔥` tarzı sistem satırı beliriyor (4 rastgele varyant).
- **Bulunan gerçek bug (bu turda düzeltildi):** `find_or_create_by!` deseni yeni `rules` alanını SADECE yeni oluşturulan odalarda dolduruyordu, mevcut (önceden var olan) 4 oda `rules` boş kalacaktı — idempotent bir backfill eklenerek düzeltildi.

### Faz 28 — Telemetri: moderatör atama + UX sadeleştirme

- Yeni `UserRolesController#update` (admin-only) — kullanıcıyı member/moderator/admin arası değiştirebiliyor, telemetri sayfasında her kullanıcı satırında otomatik-submit `<select>`.
- **Bulunan gerçek veri uyumsuzluğu (düzeltildi):** Görev tanımında örnek rol değeri `"developer"` verilmişti ama gerçek kod tabanında bu değer HİÇ kullanılmıyor — gerçek roller `"member"`/`"moderator"`/`"admin"`. Agent kod tabanını (fixture, model, mevcut testler) kontrol edip doğru değeri kullandı.
- Telemetri sayfası 3 net bölüme ayrıldı (`SİSTEM_DURUMU`, `KULLANICI_YÖNETİMİ` [rol atama + ban yönetimi birleşti], `KULLANICI_AKTİVİTE_LOGU`), zebra-stripe tablo satırları, tutarlı boşluklar — hiçbir mevcut işlevsellik (form/buton/veri) kaybolmadan.

Son doğrulama (Faz 27+28 birlikte): `bin/rails test` → 248 runs, 777 assertions, 0 failures. `bin/rubocop` → 171 dosya, temiz.

### Faz 25 — Postlar (Sosyal Akış) sayfası

- Header'a "Postlar" linki, `posts#index` gerçek infinite scroll (IntersectionObserver + Turbo Stream, sentinel deseni) ile — sayfa yenilemeden yeni post'lar akıcı fade-in ile ekleniyor.
- Sağda GERÇEKTEN post sayısına göre hesaplanan "Trend Etiketler" (statik veri değil, `posts_skills` join tablosu üzerinden `COUNT DESC`) + `#etiket` arama kutusu.
- "Post Oluştur" butonu bağlama duyarlı: akış sayfasında üstte sabit form, diğer tüm sayfalarda sol altta yüzen buton + `<dialog>` modal — geçiş CSS transition ile yumuşak, ani kaybolma/belirme yok.
- Yukarı çık butonu (300px kaydırmadan sonra beliriyor, smooth scroll).

### Faz 26 — Seed verisi hiyerarşik kategorizasyon + kapsam genişletme

- `Skill.category` 3 değerden (language/framework/tool) 9 değere çıktı (language, frontend_framework, backend_framework, database, cloud_devops, machine_learning, game_development, os_sysadmin, testing_tools) — mevcut ~95 skill'in HİÇBİRİ kaybolmadı, sadece yeni taksonomiye taşındı.
- Kapsam genişletildi: Godot, Linux/Bash/systemd/Ubuntu/Debian (yeni `os_sysadmin` kategorisi), Web3 (Ethereum/Web3.js/Hardhat), güvenlik araçları (Nmap/Wireshark/Metasploit/Burp Suite) eklendi — havuz 113 yeteneğe çıktı.
- **Bulunan gerçek bug (bu turda düzeltildi):** `find_or_create_by!` deseni, kayıt ZATEN varsa `category`'yi GÜNCELLEMİYORDU (Rails semantiği) — mevcut kayıtların kategorisi hiç taşınmayacaktı. `find_or_initialize_by` + açık `save!` desenine geçilerek düzeltildi.
- **Zincirleme düzeltme:** Kategori isimleri değişince `dashboard/index.html.erb`'deki eski `Skill.where(category: %w[language framework tool])` filtresi (post etiketleme checkbox listesi) geçersiz hale geliyordu — fark edilip `Skill.order(:name)` olarak düzeltildi.
- `profiles/edit.html.erb`'deki kategori grupları 3'ten 9'a çıktı (her biri `<details>` ile katlanabilir).

Son doğrulama (Faz 25+26 birlikte): `bin/rails test` → 243 runs, 755 assertions, 0 failures. `bin/rubocop` → 168 dosya, temiz.

### Faz 23 — GitHub repo görünürlük seçimi

- `github_repositories.visible_on_profile` (varsayılan `true` — opt-out, boş profil karşılamasın diye).
- Yeni `PATCH /github_repositories/:id` — sadece repo sahibi kendi reposunun görünürlüğünü değiştirebiliyor (`current_user.github_repositories.find_by`, başkasınınki `not_found`).
- Profil düzenleme sayfasına checkbox listesi eklendi (fetch + CSRF token ile anlık PATCH).
- **Düzeltme:** İlk teşhis "repolar hiç gösterilmiyor" şeklindeydi ama Opus agent'ı inceleyince `profiles/show.html.erb`'de `@repositories` bölümünün ZATEN VAR OLDUĞUNU buldu — gerçek eksik sadece görünürlük filtresiydi (`visible_on_profile` scope'u eklenerek tamamlandı, gereksiz bir bölüm ikiletilmedi).

### Faz 24 — Presence göstergeleri + DM okundu bilgisi

- Profil kimlik kartına `@profile_user`'ın (viewer'ın DEĞİL) durumu: yeşil "Çevrimiçi", turuncu "Eşleşmede" (bitmemiş bir private DM odasına katılımcıysa), çevrimdışıysa "Son görülme" (24 saat içinde saat, sonrasında tarih+saat).
- **Yarım kalmış bir özellik tamamlandı:** `terminal_chat_channel.js`'de zaten `mark_read`/`read_receipt` client-side mantığı vardı ama server tarafında (`terminal_chat_channel.rb`) `mark_read` action'ı HİÇ YOKTU — eklendi (`messages.read_at` + `read_receipt` broadcast).
- "Eşleşmede" tanımı (kullanıcı tam netleştirmedi, makul bir varsayımla uygulandı): `ChatRoom.where(private: true, ended_by_a: false, ended_by_b: false)` içinde katılımcı olmak. İleride ayarlanabilir.

Son doğrulama (Faz 23+24 birlikte): `bin/rails test` → 238 runs, 727 assertions, 0 failures. `bin/rubocop` → 168 dosya, temiz.

### Faz 21 — gelistirme-prompt.md: gerçek bug düzeltmeleri

`gelistirme-prompt.md`'de raporlanan, kod incelemesiyle önceden doğrulanmış 4 gerçek bug düzeltildi:

- **Presence tracking hiç kurulmamıştı** ("çevrimiçi kullanıcı: 0") — `users.is_online` kolonu sadece OKUNUYORDU, hiçbir yerde YAZILMIYORDU. Fix: `ApplicationCable::Connection#connect`/`#disconnect`'e bağlandı (kanal seviyesinde DEĞİL, bağlantı seviyesinde — çoklu-abonelik/çoklu-oda sorununu kökten çözüyor). Yeni `users.last_seen_at` kolonu da eklendi (ileride "son görülme" göstergesi için temel).
- **"Content missing" hatası** (dashboard'dan profile tıklanınca) — kök neden: sayfalama özelliğinin `nodes_grid` turbo frame'i, İÇİNDEKİ profil linklerini de kapsıyordu, Turbo profil sayfasında `nodes_grid` frame'i arayıp bulamayınca hata veriyordu. Fix: o linke `data: { turbo_frame: "_top" }` eklendi.
- **Esnek arama** (Kontrol Kulesi skill arama kutusu) — kısaltma/varyant haritası (js→JavaScript, k8s→Kubernetes, rails/ror→Ruby on Rails vb.) + normalize edilmiş (boşluk/tire/nokta duyarsız) substring karşılaştırması eklendi.
- **Hiyerarşik eşleştirme** — "Ruby on Rails" öğreten biri artık "Ruby" arayan biriyle eşleşiyor. `MatchFinder#match_normalized_skills`'e substring-içerme kontrolü eklendi (`skill_names_related?`), 3 karakterden kısa isimlerde (Go, C, R gibi gerçekten var olan tek/çift harfli diller) YANLIŞ-POZİTİF riski önlendi (uzunluk koruması).

Son doğrulama: `bin/rails test` → 225 runs, 690 assertions, 0 failures. `bin/rubocop` → 163 dosya, temiz.

### Faz 22 — gelistirme-prompt.md: akordeon davranışı + Kontrol Kulesi autocomplete

- Skill düzenleme mini-formları (Faz 15) artık gerçek akordeon: native HTML5 `<details name="...">` grubu (aynı isimdeki `<details>`'lerden biri açılınca diğerleri otomatik kapanır) + Stimulus `auto-submit` controller'ı (alan `blur`/`change` olunca form otomatik kaydediyor — "kapanırken kaydet" gibi kırılgan bir olay yakalamak yerine, veri zaten güncel tutuluyor).
- Kontrol Kulesi'ne HTML5 `<datalist>` tabanlı autocomplete metin girişi eklendi (framework gerektirmeden native tarayıcı desteğiyle) — mevcut checkbox grid/dropdown'un YANINA, backend zaten var olan `skill_name` (SkillResolver) yoluna gidiyor, controller değişmedi.

Son doğrulama: Faz 21 ile birlikte, aynı 225/690/0 sonucu.

### Faz 15 — Profil skill alanları genişletme + kanonik havuz

Fable'ın sunduğu seçeneklerden A+B+D kullanıcı tarafından onaylandı:

- **A — Yeterlilik seviyesi**: `user_skills.proficiency_level` (beginner/intermediate/advanced/expert). Şimdilik SADECE görüntüleme amaçlı, `MatchFinder`/embedding algoritmasına dahil edilmedi (bilinçli, düşük risk tercih edildi).
- **B — Not + kanıt linki**: `user_skills.note` (280 karakter sınır) + `evidence_url` (http(s) validasyonlu — `javascript:` gibi şemalar reddediliyor, XSS koruması test edildi).
- **D — Öğretim tercihi**: `users.teaching_format` (one_on_one/group/either) + `availability_note`.
- Yeni `PATCH /user_skills/:id` action'ı (skill-başına düzenleme, önceden hiç yoktu).
- Kanonik skill/tag havuzu 74'ten 99'a çıktı (25 yeni framework/araç: Flask, FastAPI, Nuxt.js, Svelte, Laravel, MongoDB, PyTorch, React Native, Unity, Jenkins, Terraform vb.) — bu havuz aynı zamanda Faz 16'nın post etiketleme sistemi için de kullanılıyor.

### Faz 20 — İlişki sonlandırma + gizli değerlendirme/puanlama + sıralama

"Eşleşme" resmi bir kayıt olmadığı için mevcut DM odası (Faz 14) ilişki konteyneri olarak kullanıldı:

- `ChatRoom#request_end!` — iki taraf da (1=1, `ended_by_a`/`ended_by_b`) sonlandırmayı onaylayınca oda "bitmiş" sayılır, her iki tarafa da karşı tarafı değerlendirme formu (1-5 + not) açılır.
- Yeni `Rating` modeli, `users.average_rating`/`ratings_count` (denormalize, her yeni puanlamada otomatik güncelleniyor).
- **Gizlilik (kullanıcı onaylı, test edilmiş):** Bireysel puan/not HİÇBİR kullanıcıya (ne rated_user'a ne başkasına) gösterilmiyor — sadece ORTALAMA puan profilde görünür. Bireysel detaylar SADECE admin'in telemetri log'unda (`rating_given` log tipi). Gizlilik ihlali testi (ayırt edici bir not ile) yazıldı ve GEÇTİ.
- Dashboard aramasına çoklu-terim desteği: "react laravel" gibi aramalarda HER İKİ terimi karşılayan aday, sadece birini karşılayandan önce sıralanıyor (`match_count DESC`), ikincil kriter `average_rating`.
- `MatchFinder`'a `average_rating` tabanlı küçük bir sıralama boost'u eklendi (max %10, gösterilen ham `score`'u değiştirmiyor — sadece sıralamayı etkiliyor, "%X eşleşme" göstergesi yanıltıcı olmasın diye).
- Telemetri sayfasına log-tipi filtresi eklendi (`log_type=login`/`message_sent`/`rating_given` vb.).
- **Bilinen bug (bu turda bulunup düzeltildi):** Çoklu-terim aramanın `GROUP BY`'lı sorgusu ile yeni sayfalama özelliğinin `@users.count` çağrısı çakıştı (`.group()`'lu relation'da `.count` Hash döner, Integer değil) — `@users = @users.to_a` ile materialize edilerek düzeltildi.

### Faz 16 — Blog-tarzı post + etiket sistemi

- Post'lar artık mevcut `Skill` taksonomisiyle (dil/framework/araç) etiketlenebiliyor (`has_and_belongs_to_many :skills`, ayrı bir tag sistemi kurulmadı — kanonik havuz yeniden kullanıldı).
- Yeni `posts#index`/`#show`/`#by_tag` — etikete göre gezinme (`/etiket/:tag`).
- Dashboard aramasına `#etiket` sözdizimi: `q=#react` yazınca doğrudan o etiketin post'larına yönlendiriliyor (çoklu-terim arama mantığından ÖNCE, ayrı bir erken-dönüş dalı).
- Post oluşturma formuna skill/etiket seçimi eklendi.

### Faz 17 — Moderatör rolü + uyarı/mute/eskalasyon + kullanıcı şikayet sistemi

Otomatik ihlal tespiti YOK (kullanıcı kararı, daha önce netleşmişti) — moderatör/admin sadece MANUEL işlem yapıyor:

- `User#moderator?`/`#staff?` (`staff? = admin? || moderator?`).
- Moderatör: post silebilir, kullanıcıya uyarı gönderebilir (`Warning`/tablo adı `warnings` ama model adı **`UserWarning`** — Ruby'nin çekirdek `::Warning` modülüyle isim çakışması bulunup düzeltildi), süreli mute atayabilir (`Mute`, chat+post+yorum tüm içerik üretimini durduruyor, `ApplicationController#require_not_muted` — global before_action DEĞİL, sadece ilgili `create` action'larında kullanılıyor, blast-radius riski böylece önlendi).
- **Moderatör BANLAYAMAZ** — `BansController` hâlâ sadece `require_admin` kullanıyor, moderatör erişim reddi testle doğrulandı. Banlaması gerektiğini düşünürse `Escalation` (açıklama + `has_one_attached :evidence_photo`, ActiveStorage bu fazda kuruldu) ile admin'e bildiriyor.
- Kullanıcılar arası **şikayet sistemi** (`Complaint`, açıklama + opsiyonel fotoğraf) de bu fazda kuruldu — ayrı planlanan "Faz 18" bu yüzden gereksiz oldu, iptal edildi.
- Admin, moderatörün yaptığı HER ŞEYİ yapabilir + banlayabilir (`require_staff` moderatör+admin'i kapsıyor, `require_admin` sadece admin).
- **Moderatör telemetri sayfasını hiç göremiyor** (kullanıcı onaylı kısıt) — `TelemetryController#show`'un en başına erken-redirect eklendi, admin/normal kullanıcı ETKİLENMEDİ (regresyon testleriyle doğrulandı).
- Uyarı/mute/şikayet kayıtları admin'in telemetri log'una (`UserActivityTimeline`) ayrı log tipleri olarak düşüyor.

Son doğrulama (Faz 15+20+16+17 birlikte): `bin/rails test` → 218 runs, 672 assertions, 0 failures. `bin/rubocop` → 160 dosya, temiz.

### Faz 13 — Kurallar onayı akışı + manuel ban sistemi

Otomatik ihlal tespiti YOK (kullanıcı kararı) — sadece root (admin) manuel banlıyor:

- Yeni `users.terms_accepted_at` kolonu + `ApplicationController`'da global `before_action :require_terms_acceptance` — giriş yapmış ama kuralları onaylamamış kullanıcı `/terms`'e yönlendiriliyor, onaylayana kadar sistemde gezemiyor. `TermsController#show`/`#accept`. Giriş yapmamış ziyaretçileri ETKİLEMİYOR (`return unless current_user` guard'ı).
- Yeni `banned_accounts` tablosu — ban, `(provider, uid)` çiftine bağlı (GitHub HESABINA), User satırı silinip yeniden oluşsa bile geçerli kalıyor. Süreli (`banned_until`) veya süresiz, açıklamalı (`reason`), `active` flag ile aç/kapa.
- `ApplicationController`'da global `before_action :enforce_not_banned` (her istekte kontrol, banlanan biri bir sonraki isteğinde otomatik `reset_session` ile atılıyor) + `SessionsController#create`'de login anında engelleme (daha iyi UX).
- Telemetri sayfasına admin-only ban yönetimi UI'ı: kullanıcı seç, süre (gün, boş=süresiz), açıklama gir, banla; aktif banları listele, kaldır.
- **Blast-radius riski dikkatle yönetildi:** global `require_terms_acceptance` before_action'ı, fixture'lardaki ve ~70 `User.create!` çağrısındaki (14 test dosyası) kullanıcıların hepsini etkileyebilirdi — hepsine `terms_accepted_at: Time.current` eklenerek mevcut suite korundu, sıfır regresyon.

### Faz 14 — Eşleşme sonrası özel 1:1 sohbet odası

Mevcut oda-bazlı (genel/backend/frontend/kariyer) yayın mimarisinin üzerine, sadece 2 katılımcıya açık DM odaları:

- `chat_rooms`'a `private`/`user_a_id`/`user_b_id` eklendi (`[user_a_id, user_b_id]` unique index, id-normalize edilmiş — A,B ve B,A hep aynı odaya çözülüyor, çift oda oluşmuyor). `ChatRoom#participant?`/`#display_name_for`/`.find_or_create_dm_between`/`.visible_to(user)`.
- `RoomsController#start_dm` — eşleşme profilindeki "Sohbet Aç" butonundan (`profiles/show.html.erb`, `@match.is_a?(MatchFinder::Match)` bloğunda) DM odasını bulup/oluşturup yönlendiriyor.
- **En kritik kısım — yetkilendirme üç katmanlı:** `RoomsController#show` (yanlış katılımcı → redirect), `MessagesController#create` (yanlış katılımcı → 403), `TerminalChatChannel#subscribed` (yanlış katılımcı → `reject`, ActionCable abonelik reddi). Üçü de spoof edilebilir `params[:user]`'a DEĞİL, `ApplicationCable::Connection`'ın zaten var olan `identified_by :current_user` (session tabanlı, sunucu doğrulamalı) mekanizmasına dayanıyor.
- Sekme çubuğunda (`_room_tabs`) DM odaları genel odalardan görsel olarak ayrıldı, oda adı yerine `display_name_for(current_user)` (karşı tarafın adı) gösteriliyor.
- Route: `post "rooms/dm/:user_id", to: "rooms#start_dm", as: :start_dm_room` — Faz 13'ün route'larıyla çakışmadan `config/routes.rb`'ye eklendi (paralel çalışmaya rağmen, iki farklı anchor noktası kullanıldığı için).

Son doğrulama: `bin/rails test` → 147 runs, 444 assertions, 0 failures. `bin/rubocop` → 128 dosya, temiz.

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

