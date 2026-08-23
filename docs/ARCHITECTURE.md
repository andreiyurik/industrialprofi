# Architecture — shipped subsystems

The map of what's built: one line per subsystem, with the constraints each
carries. This lives outside `CLAUDE.md` on purpose — it inventories what the
code already records and drifts as features ship, whereas `CLAUDE.md` holds
decisions and conventions, not an inventory.

For *when* and the full commit rationale, use git history; for the *forward*
roadmap (v0.3 + what we refuse to build), see `docs/VISION.md → Roadmap & scope`.

- **Accounts & progress (v0.2):** registration/login, binary `LessonCompletion`
  (Turbo Stream), per-stage/per-path progress bars, `/dashboard` continue links,
  desktop two-column lesson layout.
- **Signup:** Fizzy pattern — email → 6-char code (15 min) → name + password;
  `Signup` PORO (no table), User created only at the final step. **Production
  signup REQUIRES SMTP.** Login stays password-based on purpose; post-signup
  founder welcome `<dialog>`.
- **Password reset:** `generates_token_for`, `PasswordsController` + mailer.
- **Editing pipeline:** readers *suggest* a section edit (rate-limited + honeypot)
  → editor reviews → every applied change appends an immutable `LessonRevision`;
  reader-facing `/revisions`. Rollback = a new revision, never a rewrite.
- **Roles trust ladder:** `member` → `editor` («Эксперт», `can_edit_content?`) →
  `administrator` (`can_administer?`, can't change own role). `Editorship` scopes
  editor rights to granted professions; only admins publish. First admin via
  `ADMIN_EMAIL`/`ADMIN_PASSWORD` seed.
- **Admin dashboard (`/admin`):** signups 12-week CSS bar chart, active-this-week,
  pending suggestions, completions, journal volume, content health, `SystemStatus`
  vitals (disk + SQLite footprint, Solid Queue health, `MailMetrics`). Plain
  group/count queries, no charting JS, no admin gems; scaling seam = `Rails.cache.fetch`.
- **Admin action log (`/admin/log`):** `AdminAction` append-only transparency log
  (role changes, grants, approve/reject, rollback, suspend) — second audit trail.
  Immutable, denormalized `details` JSON, keyset pagination + category/actor
  filters, no free-text search. Wiki *data* mechanics, NOT its social governance.
- **User detail card (`/admin/users/:id`):** profile + role/suspend controls,
  snapshot, progress, active sessions (force-logout), recent activity.
- **User suspension:** `users.suspended_at`; `suspend!` revokes sessions and
  `User.active.authenticate_by` blocks login; reversible (`reinstate!`),
  self-suspend guard. No durations/IP/partial blocks.
- **Practice journal + heatmap:** `JournalEntry` (`/journal`) — private,
  **text-only** work log (rich text + optional lesson link, rate-limited). The
  16-week heatmap counts completions + journal entries. **No photo uploads**
  (north star).
- **Focus direction:** `User#focus_path` (derived from latest completion, no
  stored setting) drives the dashboard hero, catalog banner, `/projects` sort.
  Defaults, not walls — nothing is locked.
- **Contributor attribution:** muted "Статью улучшили" credit from `LessonRevision`
  (founder's direct edits store `editor_name: nil`, so he never appears).
  Generated-initials avatars, no uploads.
- **Profession landing («О профессии», `Path::Landing`):** six content slots in
  one JSON column (`paths.landing`: about/history/faq markdown, highlights/pros/
  cons line-lists) + `has_one_attached :cover` (upload policy = lesson images;
  doubles as the page's og:image). Edited as textareas in the profession form,
  carried by the pack as `landing.yml` + `cover.*`; rides the importer's freeze
  (an expert's edit → the pack never overwrites), but an EMPTY landing is filled
  even on a human-owned profession (`Path#fill_landing` — creating, not overwriting). Universal by design: national
  specifics live in prose, not schema; a new slot is code when two professions ask.
- **Profession hub (`/paths/:slug` + `/theory` + `/practice` + `/glossary` +
  `/library`):** one profession, one header (emblem, description, «N глав · M
  статей · K заданий», curators, «карту улучшили N участников» popover,
  maturity) and its tabs — Обзор (the landing + a chapter outline), Теория
  (the programme: chapter cards, continue CTA), Практика (that profession's tasks on the difficulty
  ladder), Словарь (its abbreviations — `GlossaryTerm` rows owned by the
  lesson that explains each, edited in the lesson editor next to the links,
  `terms:` in the pack frontmatter; the tab exists only where lessons define
  any), Библиотека (its documents + calculators). `Path::Progress` is
  the per-reader null-object the hub views read (no `Current.user` branching).
  The old `?path=` views of `/projects`, `/resources`, `/glossary` 301 into the
  hub; the site-wide pages stay (footer + palette), out of the top bar. Every
  tab ends in «Улучшить карту» — the existing contribution doors, in context.
- **Projects (`/projects`):** aggregator of all `kind: practice` lessons across
  published paths, difficulty filters; each profession heading leads into its hub.
- **Calculators (`/calculators`):** trade formula tools — code registry (no DB) +
  one Stimulus controller for all math.
- **Search (`/search`):** SQLite FTS5 behind the `LessonSearch` PORO (all FTS SQL
  there); `Lesson` commit callbacks sync the index (`bin/rails search:rebuild`
  after a restore). Published-only, bm25 title > description > body, quoted-prefix
  terms (RU morphology + injection safety), `<mark>` snippets. Live form =
  debounced auto-submit into a Turbo Frame (input outside the frame keeps focus).
  Zero new dependencies.
- **Command palette (`shared/_palette`):** Fizzy's jump menu — header search icon
  (real link to `/search` = no-JS fallback), Ctrl/Cmd+K (k/л) or `/` opens a
  `<dialog>` with live FTS5 in a `palette_results` frame, quick-destination tiles
  while blank (guest vs signed-in), colophon → `/contribute`. One Stimulus
  controller; no arrow-key nav on purpose — Enter/click covers it.
- **Content export (`content:export[slug]`):** `CurriculumExporter` writes a
  profession from the DB back into the exact YAML/Markdown tree the importer reads
  — a portable pack for on-prem installs, offline authoring, content that outlives
  the platform. Round-trip covered by tests; drag-reordered stages split into
  consecutive same-title dirs so import reproduces order.
- **Retention email (the ONE):** `LearningReminderJob` (daily Solid Queue
  recurring) nudges stalled learners once per stall — never a drip. Opt-out +
  tokenized one-click unsubscribe (RFC 8058). **No more lifecycle emails without
  an explicit founder decision.**
- **Feedback line («Написать автору»):** async `Feedback` → founder reads at
  `/admin/feedbacks` (unread badge) + email per message. **NOT a chat.**
- **Error monitoring (gem-free):** `ErrorSubscriber` on `Rails.error` emails
  administrators on unhandled exceptions (throttled via Solid Cache). No
  Sentry/Honeybadger — this + an external `/up` ping is the whole story.
- **Participation page (`/contribute`):** open-project page, split from
  `/support_us` (money). The future-co-author surface where the wide vision is
  voiced; includes the public "wanted professions" board (`ru.yml →
  contribute.wanted`, a curated excerpt of `docs/PROFESSION_BACKLOG.md`).
- **Partners (`/partners`):** adaptive sponsors page (invitation while empty),
  curated constant, independence firewall.
- **Milestone dialog:** finishing a course/profession opens a celebration
  `<dialog>` (stats + Telegram share) via the completion Turbo Stream — the one
  honest share moment; a section keeps the quiet flash pill.
- **B2B demand sensor (`/business`):** public pitch + inquiry form → tagged guest
  `Feedback`. Paid offer (2026-07): on-prem closed-contour deploy (zero new code,
  Kamal image on THEIR servers) + closed учебные карты for training centers; AGPL
  stays, revenue = внедрение + annual support via ИП. Still a sensor — first
  clients get manual bespoke delivery; build B2B features (esp. hosted tenants —
  deferred, SQLite/liability) only from real repeated inquiries.
- **Analytics:** Yandex Metrika, only when `YANDEX_METRIKA_ID` is set
  (`shared/_metrika`). Idle-loaded (ym() stub queues, tag.js on
  requestIdleCallback, 3 s cap); hits per `turbo:load`. Disclosed in `/privacy` —
  keep it truthful. GA rejected (152-ФЗ + no Google Ads in RU).
