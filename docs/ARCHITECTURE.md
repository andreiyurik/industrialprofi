---
summary: The shape of the running system and the map of its subsystems — start here before reading code.
---

# Architecture

A majestic monolith on one small VPS: Rails 8.1, SQLite on one disk, Solid
Queue/Cache/Cable, Hotwire, Kamal. No Node, no S3, no paid SaaS — see the north star in
[AGENTS.md](../AGENTS.md).

```mermaid
flowchart LR
  subgraph People
    Reader[Guest reader]
    Member
    Expert[Editor «Эксперт»]
    Admin[Administrator]
  end
  subgraph VPS["One VPS · Kamal · Thruster"]
    Rails["Rails 8.1 monolith<br>ERB + Turbo + Stimulus"]
    Jobs["Solid Queue jobs<br>reminders · suggestion emails · blob purge · disk alert"]
    DB[("production.sqlite3<br>+ cache · queue · cable")]
    Blobs[("storage/blobs<br>lesson images · covers · photos")]
  end
  People --> Rails
  Rails --> DB
  Rails --> Blobs
  Jobs --> DB
  Jobs --> SMTP[SMTP]
  Rails --> SMTP
  Packs["Content packs<br>db/seeds/curriculum · zip import"] -- "create-only import" --> DB
```

## Subsystems

- [Content model](conventions/content-model.md) — Path → Course → stage → Lesson, invariants, importer.
- [Profession hub](architecture/profession-hub.md) — the five tabs, landing, glossary, library, projects, calculators.
- [Learning loop](architecture/learning-loop.md) — completion, dashboard, journal, the one retention email.
- [Editing pipeline](architecture/editing-pipeline.md) — suggestions → review → immutable revisions, attribution.
- [Accounts and roles](architecture/accounts-and-roles.md) — signup, trust ladder, grants, suspension, profiles.
- [Personal maps](architecture/personal-maps.md) — overlays on a profession, never copies.
- [Search and palette](architecture/search-and-palette.md) — FTS5 and Ctrl+K.
- [Admin and operations](architecture/admin-and-operations.md) — dashboard, action log, feedback, errors, analytics.

For *when* and the full rationale, use git history; for the forward roadmap, see
[VISION → Roadmap & scope](VISION.md#roadmap--scope).
