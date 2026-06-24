# Deploy — step by step

The first deploy, step by step; every deploy after that is a single command.
Stack: one VPS, Kamal 2, Docker, SQLite on a persistent volume. Everything is
already wired up in the repo (`config/deploy.yml`, `.kamal/secrets`, the
production config) — you just fill in your own values and work down the list.

## 0. Prerequisites

- **VPS** — 2 GB RAM is enough (SQLite, single container). A clean Ubuntu LTS,
  root access over an SSH key. No need to install Docker — Kamal installs it.
- **Domain** `industrialprofi.com` — an A record pointing at the server IP (and
  `www` if you want it). Check: `dig +short industrialprofi.com` returns the IP.
- **GitHub PAT** (Settings → Developer settings → Tokens classic) with the
  `write:packages` scope — for the ghcr.io image registry.
- **SMTP provider** — mail is mandatory: without it, registration (the emailed
  code), password reset, and error alerts don't work. Any transactional SMTP that
  delivers to RU domains works (e.g. smtp.mail.ru for business / Unisender /
  Mailopost).

## 1. Secrets

```bash
# SMTP — into encrypted credentials (needs config/master.key):
bin/rails credentials:edit
```

```yaml
# add the block:
smtp:
  address: smtp.example.com
  port: 587
  user_name: no-reply@industrialprofi.com
  password: "..."
```

```bash
# Registry token — into the shell environment (NOT in git):
export KAMAL_REGISTRY_PASSWORD=ghp_...   # put it in ~/.bashrc
```

`config/master.key` is not committed — keep a copy in a password manager.

## 2. Config

In `config/deploy.yml` replace the two TODOs: the server IP (`servers.web`) and
the ghcr.io username. Nothing else there needs touching.

## 3. First deploy

```bash
bin/kamal setup        # installs Docker on the server, builds the image, brings
                       # up kamal-proxy with Let's Encrypt, starts the app;
                       # the DB is created and migrated automatically on boot
```

Create the first administrator and the content:

```bash
ADMIN_EMAIL=... ADMIN_PASSWORD=... bin/kamal app exec "bin/rails db:seed"
```

## 4. Smoke test (don't skip)

1. `https://industrialprofi.com/up` → 200, the browser lock icon is valid.
2. Register with a real mailbox — the code must arrive (this verifies SMTP).
3. Sign in as admin → `/admin` opens.
4. Mark any lesson as done, create a journal entry (text-only).
5. Check alerts: `bin/kamal console` →
   `Rails.error.report(RuntimeError.new("deploy smoke test"), handled: false)` —
   an email must reach an administrator.

## 5. Right after the first deploy

- **Backups — mandatory, before any real users exist.** Data lives on the host
  in the docker volume
  `/var/lib/docker/volumes/industrialprofi_storage/_data` (the SQLite databases).
  At minimum, a daily cron on the server (`apt install sqlite3 rclone`):
  ```bash
  # .backup is consistent even under load (SQLite online backup API)
  sqlite3 /var/lib/docker/volumes/industrialprofi_storage/_data/production.sqlite3 \
    ".backup /root/backups/production-$(date +%F).sqlite3"
  rclone sync /root/backups remote:industrialprofi-backups
  ```
  Active Storage blobs are ≈0 (journal uploads were removed), so the SQLite
  databases are the whole dataset. The better option is Litestream (streaming
  SQLite replication to S3) as a Kamal accessory — set it up at the first free
  moment. A backup you've never restored isn't a backup — restore a dump locally
  once a quarter.
- **External uptime monitoring:** UptimeRobot (free) on
  `https://industrialprofi.com/up`, alerting to email/Telegram. Internal error
  monitoring is already built in (`lib/error_subscriber.rb` emails admins).
- Record the access for VPS, domain, registry, SMTP, and `master.key`
  **out-of-band** (a password manager) so the project can survive the bus factor.
  Per a recorded decision, this never lives in the repo.

## Routine

```bash
bin/kamal deploy       # every subsequent deploy (a green CI is required first)
bin/kamal logs         # tail the logs
bin/kamal console      # rails console on production
bin/kamal rollback     # roll back to the previous image if a deploy is bad
```

The rule from VISION: ship weekly — a deploy is routine, not an event.
</content>
