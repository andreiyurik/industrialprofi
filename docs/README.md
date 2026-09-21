# Docs index

The project wiki: one page per subject, one line per page here. Read this first, then
open only what the task needs. How the wiki is kept is in
[conventions/docs.md](conventions/docs.md). Content-authoring docs are in Russian under
`tools/` (start at `tools/CONTENT_FACTORY.md`).

## Product

- [VISION](VISION.md) — what we build, for whom and why; business model, roadmap, the not-building list.
- [PROFESSION_BACKLOG](PROFESSION_BACKLOG.md) — which professions to package next and why.
- [SOURCING](SOURCING.md) — where each trade's world-best practice comes from.

## Architecture

- [ARCHITECTURE](ARCHITECTURE.md) — the running system on one page; links to every subsystem.
- [Profession hub](architecture/profession-hub.md) — landing, theory, practice, glossary, library tabs.
- [Learning loop](architecture/learning-loop.md) — completion, dashboard, journal, retention email.
- [Editing pipeline](architecture/editing-pipeline.md) — suggestions → review → immutable revisions.
- [Accounts and roles](architecture/accounts-and-roles.md) — signup, trust ladder, grants, profiles.
- [Personal maps](architecture/personal-maps.md) — overlays on a profession, never copies.
- [Search and palette](architecture/search-and-palette.md) — FTS5 search and Ctrl+K.
- [Admin and operations](architecture/admin-and-operations.md) — dashboard, action log, feedback, monitoring.

## Conventions

Loaded automatically by Claude Code when it touches the matching files (`.claude/rules/`).

- [rails](conventions/rails.md) — controllers, models, jobs, tests.
- [views](conventions/views.md) — ERB, Turbo, i18n, emblems, account menu.
- [css](conventions/css.md) — stylesheet layout, OKLCH tokens, fonts, spacing, icons.
- [javascript](conventions/javascript.md) — Stimulus shape, helpers, native Web APIs.
- [content-model](conventions/content-model.md) — hierarchy, invariants, importer.
- [lessons](conventions/lessons.md) — the lesson and practice-task format.
- [docs](conventions/docs.md) — how this wiki is written, linted and opened in Obsidian.

## Decisions

Settled — don't re-propose without the listed trigger.

- [2026-06-12 Narrow wedge, wide ceiling](decisions/2026-06-12-narrow-wedge-wide-ceiling.md) — claims stay narrow, the author board spans wide.
- [2026-06-22 No continuity runbook](decisions/2026-06-22-no-continuity-doc.md) — bus-factor mitigation lives out-of-band.
- [2026-06-24 No realtime chat](decisions/2026-06-24-no-realtime-chat.md) — async feedback with an honest SLA.
- [2026-06-24 No leaderboard](decisions/2026-06-24-no-leaderboard.md) — attribution, not competition.
- [2026-06-24 No uploads on private models](decisions/2026-06-24-no-uploads-on-private-models.md) — the SQLite disk is the app's life.
- [2026-06-24 Monetization deferred](decisions/2026-06-24-monetization-deferred.md) — free forever, retention before revenue.
- [2026-06-24 No wiki social governance](decisions/2026-06-24-no-wiki-social-governance.md) — wiki data mechanics only.
- [2026-06-27 Callouts are blockquotes](decisions/2026-06-27-callouts-are-blockquotes.md) — no custom editor block.
- [2026-06-27 Lesson images: editor-gated](decisions/2026-06-27-lesson-images-editor-gated.md) — no SVG, no watermark, local blobs; web-filled placeholders too.
- [2026-07-11 Lessons have no draft status](decisions/2026-07-11-lessons-have-no-draft-status.md) — transparency over a gate.
- [2026-07-15 SQLite backups, not Litestream](decisions/2026-07-15-sqlite-backups-not-litestream.md) — `.backup` + cron + rclone.
- [2026-07-16 No notification bell](decisions/2026-07-16-no-notification-bell.md) — the one loop is already closed.
- [2026-07-16 Unwritten profession is copy](decisions/2026-07-16-unwritten-profession-is-copy.md) — never an empty Path.
- [2026-07-31 No community maps shelf](decisions/2026-07-31-no-community-maps-shelf.md) — sandbox + promotion instead.
- [2026-07-31 Spacing primitives: three sizes](decisions/2026-07-31-spacing-primitives-three-sizes.md) — no fourth tier.
- [2026-08-04 Symmetric URL locales](decisions/2026-08-04-symmetric-url-locales.md) — `/ru` and `/en`, content in one locale.
- [2026-09-21 Users before features](decisions/2026-09-21-users-before-features.md) — measure real learners on one profession before building more.

## Operations

- [DEPLOY](DEPLOY.md) — first-deploy runbook, backups, monitoring.
