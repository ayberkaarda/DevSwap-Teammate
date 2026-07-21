# Cable Architecture Notes

**Current state:** ActionCable in production runs on a single Solid Cable queue backed by Postgres (`config/cable.yml`), with `polling_interval: 0.3.seconds` and `message_retention: 1.hour`. This one queue is shared by all channels: chat (`TerminalChatChannel`), `dev_feed`, and Turbo Streams telemetry broadcasts. Solid Cable's `polling_interval` is a single global value per adapter config, not per-channel, so there is currently no per-channel tiering.

**Future work (trigger: approaching 10K CCU):** Split cable traffic onto a genuinely separate Postgres *instance*, not just a second logical database on the same instance — WAL and buffer cache are shared per-instance, so a second DB alone doesn't provide real isolation. Once traffic runs on a dedicated instance, evaluate a fast/slow channel split, e.g. chat at ~0.1s polling on one instance and dev_feed/telemetry at 0.5-1s on another.

## Connection Pool Audit (2026-07-15)

**Bug found and fixed:** `config/database.yml` used an invalid key `max_connections` instead of the correct ActiveRecord key `pool`. This meant the connection pool size was silently defaulting to ActiveRecord's built-in default (5) regardless of the `RAILS_MAX_THREADS` env var, for every database (primary/cache/queue/cable) in every environment. Fixed by renaming the key to `pool`.

**Config mismatch noted (not fixed, informational):** `config/puma.rb` falls back to `RAILS_MAX_THREADS` = 3 if unset, while `config/database.yml`'s pool falls back to 5 if unset. If `RAILS_MAX_THREADS` is never set explicitly in production, Puma runs 3 threads/process but each database pool reserves 5 connections/process — safe (pool ≥ threads) but wasteful. Recommend explicitly setting `RAILS_MAX_THREADS=5` in production so Puma threads and AR pool size are aligned by the same env var, as originally intended.

**Puma process count is undefined by puma.rb itself:** there is no `workers N` call in `config/puma.rb` — Rails 8's default template relies on running multiple *containers* (e.g. via Kamal) rather than Puma's built-in cluster mode for horizontal scaling. So "Puma process count" (`P` below) is a deployment-time parameter (number of app server replicas), not something visible in this repo's config alone.

**Formula:** with 4 logical databases (primary, cache, queue, cable) all sharing the same pool size `T` = `RAILS_MAX_THREADS` (recommended explicit value: 5), and 3 additional Solid Queue processes that each also open connections across the same 4 databases in the worst case (1 dispatcher + 1 general worker process at `JOB_CONCURRENCY` default 1 + 1 dedicated `github` queue worker process, per `config/queue.yml`):

```
Total connections (worst-case ceiling) = (P + 3) × 4 × T
                                        = (P + 3) × 20   [at T=5]
```

**Concrete thresholds** (stock Postgres `max_connections` default is 100, minus `superuser_reserved_connections` default 3, minus headroom for `bin/rails console`/migrations/monitoring — effective safe budget is closer to ~90):

| P (Puma processes) | Worst-case connections | vs. stock max_connections=100 |
|---|---|---|
| 1 | 80 | OK, thin margin |
| 2 | 100 | **At the limit — no headroom** |
| 4 | 140 | **Over capacity** |

**Conclusion:** this app hits stock Postgres connection capacity at just **2 horizontally-scaled Puma processes**, before accounting for admin/monitoring connections. This is a real near-term constraint for a 10K CCU target, not a hypothetical one.

**Recommendation (not implemented yet, per explicit scope of this task):**
- Short term: raise Postgres `max_connections` (note the RAM cost — each Postgres connection reserves roughly 5-10MB, so going from 100 to 150 connections costs ~0.5-1GB of RAM even when idle) and/or lower `T`/pool sizes if measured concurrency doesn't need 5.
- Medium term (this is the real fix, matching the item's instruction not to stand up PgBouncer yet): introduce PgBouncer in transaction-pooling mode in front of Postgres once `P` reaches 2, since the worst-case ceiling is already at the stock limit at that point. This should happen well before any dual-Postgres-instance cable split discussed above.

**Windows dev note:** this audit is static config analysis; nothing here required running the Solid Queue supervisor (`bin/jobs`), which is known to crash on Windows via `fork()` — not applicable to this task.
