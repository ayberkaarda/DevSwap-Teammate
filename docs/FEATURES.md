# FEATURES

Özellik alanı → ilgili dosya eşlemesi. Satır numaraları kasıtlı olarak verilmedi (dosyalar zamanla değişir).

## Eşleştirme (Matching)

Kullanıcıların pgvector ile hesaplanmış teach/learn embedding'lerine dayanarak birbirleriyle çapraz eşleştirilmesi (kim kime öğretebilir / kimden öğrenebilir), skor/karşılıklılık/eşleşme nedeni üretimi ve dashboard'da sunulması.

- app/services/match_finder.rb
- app/services/user_embedding_builder.rb
- app/jobs/generate_user_embedding_job.rb
- app/models/user_skill_vector.rb
- app/models/user_skill.rb
- lib/tasks/embeddings.rake
- app/controllers/dashboard_controller.rb
- app/views/dashboard/index.html.erb
- docs/architecture-review.md

**Not — `app/jobs/match_calculation_job.rb`:** Bu, `MatchFinder`'dan tamamen ayrı, farklı bir mekanizma. `Post` modelinde `after_create_commit :trigger_match_calculation` kancasıyla her yeni post oluşturulduğunda `MatchCalculationJob.perform_later(self)` çağrılıyor (bkz. app/models/post.rb). Job'ın kendisi ise sadece 2 saniye `sleep` edip "eşleştirme hesaplaması başladı/tamamlandı" loglayan boş bir gövde — gerçek bir hesaplama yapmıyor. Muhtemelen ileride bir özellik için bırakılmış iskelet/placeholder bir job; şu anki pgvector tabanlı eşleştirme akışıyla (`MatchFinder`) hiçbir bağlantısı yok.

## Terminal Chat

Tüm kullanıcıların ortak, global bir "terminal" arayüzünde gerçek zamanlı (Action Cable) sohbet etmesi; mesaj oluşturma, yayın (broadcast) ve yazıyor göstergesi (typing indicator, sunucu taraflı debounce ile).

- app/channels/terminal_chat_channel.rb
- app/javascript/channels/terminal_chat_channel.js
- app/models/message.rb
- app/controllers/messages_controller.rb
- app/javascript/channels/consumer.js

## Telemetri (Telemetry)

Sistem durumunun (çevrimiçi kullanıcı sayısı, dakikadaki mesaj sayısı, kuyruk job'ları, GitHub taramaları, üretilen embedding sayısı, popüler yetenekler) periyodik olarak hesaplanıp Turbo Streams ile canlı yayınlandığı, ayrıca periyodik olarak veritabanına kaydedilip geçmişinin tutulduğu bir izleme paneli.

- app/controllers/telemetry_controller.rb
- app/models/telemetry_snapshot.rb
- app/jobs/telemetry_tick_job.rb
- app/views/telemetry/show.html.erb
- app/views/telemetry/_widgets.html.erb

## Tema / Görünüm (Theme/Skin)

Arayüzün açık/koyu tema geçişi ve terminal panelinin macOS/Windows görünümleri arasında geçiş yapabilmesi; bu davranışları yöneten Stimulus controller'ları ve tasarım token'larının (renk, tipografi vb.) tanımlandığı Tailwind yapılandırması.

- app/javascript/controllers/theme_controller.js
- app/javascript/controllers/terminal_skin_controller.js
- app/assets/tailwind/application.css
- config/tailwind.config.js

## Kimlik Doğrulama (Auth)

GitHub OmniAuth ile giriş/çıkış, kullanıcının oturum bilgisiyle oluşturulması/güncellenmesi ve girişten sonra tetiklenen arka plan GitHub yetenek taraması (repo dillerinden teaching skill'leri çıkarıp embedding hesaplamasını tetikleme).

- app/controllers/sessions_controller.rb
- config/initializers/omniauth.rb
- app/models/user.rb
- app/jobs/github_scan_job.rb

## Profil

Kullanıcının kendi profilini (isim, bio) düzenlemesi ve öğretebileceği/öğrenmek istediği yetenekleri (skill) ekleyip çıkarabilmesi; her ekleme/çıkarmada embedding'in yeniden hesaplanmak üzere kuyruğa alınması.

- app/controllers/profiles_controller.rb
- app/views/profiles/edit.html.erb
- app/helpers/profiles_helper.rb
- app/controllers/user_skills_controller.rb
- app/helpers/user_skills_helper.rb
