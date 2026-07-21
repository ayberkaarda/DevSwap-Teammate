# Deploy Checklist

Prod'a çıkmadan önce doğrulanması gereken maddeler.

## Real-time / ActionCable

- [ ] **Solid Cable poll churn izleme** — Faz 10 (oda-bazlı stream'ler) mimari rapor §1.2'nin 10K CCU önkoşulunu karşılıyor (global stream O(N²) sorunu çözüldü), ancak oda sayısı arttıkça poll churn'ü (stream sayısı × Puma süreci × polling_interval) hiç ölçülmedi. İlk gerçek trafik öncesi `solid_cable_messages` tablosunun INSERT/DELETE hacmini ve autovacuum gecikmesini izleyin. Mevcut ayar: `polling_interval: 0.3.seconds`, `message_retention: 1.hour` (`config/cable.yml`). Detay: `docs/architecture-review.md` §1.

## Background Jobs / Solid Queue

- [ ] **`TelemetryPartitionMaintenanceJob`'un ilk Linux/production deploy'unda gerçekten çalıştığı doğrulanmalı** — 03:00 zincirinin (`config/recurring.yml`) gelecek ay partition'larını açtığı ve 12 aydan eski partition'ları düşürdüğü kontrol edilmeli. Partition açılmazsa `activity_logs`/`telemetry_snapshots` yazımları hata verir.
- [ ] **Windows geliştirme ortamında Solid Queue'nun standart çalıştırma yolları ÇALIŞMIYOR** — `bin/jobs` (Supervisor, `SIGQUIT` sinyali desteksiz) ve Puma'nın `plugin :solid_queue`'su (`Process.fork` desteksiz) native Windows Ruby'de çöküyor (doğrulandı). Bunun yerine `bin/dev_worker` (Supervisor'sız, thread-tabanlı, sadece dev için) kullanılıyor. Production/Linux'ta bu script KULLANILMAZ, `bin/jobs` kullanılır — deploy sürecinde `bin/dev_worker`'ın yanlışlıkla production'a taşınmadığından emin olun.

## Database

- [ ] Migration'lar uygulandı (`bin/rails db:migrate`).
- [ ] Seed'ler `SEED_RESET` olmadan, idempotent şekilde çalıştırıldı.
