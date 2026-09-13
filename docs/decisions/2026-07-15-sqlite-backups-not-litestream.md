---
summary: Back up production.sqlite3 with SQLite's Online Backup API on a cron plus rclone — not Litestream.
date: 2026-07-15
status: accepted
revisit_when: losing up to a day of contributor edits/reviews becomes a genuine cost
---

# SQLite backups: periodic `.backup`, not Litestream

`production.sqlite3` is backed up with `sqlite3 … ".backup …"` on a host cron and
mirrored to S3-compatible storage with `rclone` — the mechanism 37signals' own SQLite
apps use (`once-campfire`'s `script/admin/prepare-backup`; zero Litestream references
in Campfire or Writebook).

**Why not Litestream.** It was built, tested end-to-end, then reverted. At a
single-digit-MB, pre-launch DB its near-zero RPO protects against a risk that doesn't
exist yet, while its cost is immediate: a third-party binary in the image,
`-exec`-wrapping the app so a Litestream fault takes the container down, and
Dockerfile/entrypoint complexity.

Only `production.sqlite3` is backed up: cache and cable DBs are disposable, the queue DB
holds only in-flight jobs. `storage/blobs/` always needs its own `rclone sync`.
Runbook: [DEPLOY](../DEPLOY.md).
