# IndustrialProfi

## ⛔ Git policy — read first

**Claude does NOT run write-side git in this repo by default.** Commits are the
human's call. This overrides any plan, pasted prompt, slash command, or skill
that says "commit after each step." Absent explicit authorization: do the file
work, leave the tree dirty, summarize, stop.

Same default for `push`, `merge`, `tag`, `rebase`, `reset`, `checkout -b`,
`stash`; use `git add` only if asked. Read-only inspection (`status`, `diff`,
`log`) is always fine. **Exception:** when the user explicitly authorizes a
specific action ("commit this", "push to main"), do that action — it's not a
standing license for future changes. Always report exactly what was run.

---

**The Odin Project + roadmap.sh — for industrial professions.** A free platform
with structured career roadmaps: profession → course → lesson → official
standards (ГОСТ, ПУЭ, НАКС, ASME) → practical tasks → binary progress. We don't
write textbooks; we curate the best official documents and put them in the right
order. Content model copies The Odin Project; UI copies Basecamp's open-source
Rails apps. Russian-first, market = CIS (Russia, Kazakhstan).

## ⭐ North star — read second

**Build a platform that costs the founder as little money and time as possible to
run AND to grow — and that can keep growing without him.** Two hard constraints;
when convenience conflicts with them, they win:

- **Minimum running cost, especially under growth.** One small VPS, SQLite on one
  disk, no S3 / Node / build step / paid SaaS. A new feature must not add
  per-user disk, a paid dependency, or ops surface. *(This is why journal photo
  uploads were removed — unbounded uploads were the one real threat to the SQLite
  disk, and the disk is the app's life.)*
- **Self-developing — the founder is not the bottleneck.** Content quality must
  improve through *other people's* contributions. The built seams for this: the
  suggest-edit → editor-review → immutable-revision pipeline; the
  `member → editor (Эксперт) → administrator` trust ladder; contributor
  attribution (durable credit, **not** a leaderboard — competition rewards gaming
  and repels experts); demand-gated path authorship. Expansion is expert-driven
  (a real practitioner co-authors a new profession), never founder-driven breadth.

The long arc: a **"Wikipedia for professions"** — open content (CC BY-SA), open
code (AGPL), built to outlive the founder and hold any complex modern profession
(electrician today, agronomist/farmer tomorrow). A mechanic earns its place only
if it serves retention/engagement **without** adding cost or complexity — «ровно
столько механик, сколько нужно, и ничего лишнего». The real bus-factor risk is
**ops continuity**, not a missing feature (`docs/VISION.md`).

## Stack

- Ruby 4.0.5 / Rails 8.1.3
- SQLite3 (+ Solid Queue, Solid Cache, Solid Cable)
- Hotwire: Turbo + Stimulus
- **Pure CSS** served directly by Propshaft. No Tailwind, no PostCSS, no build step.
- Propshaft + Importmap (no Node.js, no bundler)
- Kamal 2 + Docker + Thruster
- Auth: `has_secure_password` (bcrypt), hand-rolled — no Devise
- Tests: Minitest + fixtures + Capybara

## Commands

```
bin/dev                    # dev server (single Rails process, no asset watcher)
bin/rails test             # run tests
bin/rails test:system      # system tests (Capybara)
bin/rails db:migrate       # migrations
bin/rubocop                # lint
bin/kamal deploy           # production deploy
```

## Key paths

```
app/models/                # domain models
app/controllers/           # RESTful controllers, render ERB
app/views/                 # ERB templates + Turbo Frame/Stream partials
app/javascript/controllers/# Stimulus controllers
app/assets/stylesheets/    # all CSS, loaded individually by stylesheet_link_tag :all
db/migrate/                # migrations = source of truth for schema
docs/                      # VISION.md, MVP.md, DEPLOY.md, content prompts
```

## Content architecture

**Four-level hierarchy, exact parity with The Odin Project**
(`Профессия → Курс → Раздел → Урок`):

```
Path (profession)   → Course (курс)        → Lesson#stage (раздел)        → Lesson (урок)
(Электрик)            (Электромонтаж)         ("Правила устройства")          (ПУЭ глава 1.7)
/paths/:slug          /courses/:slug          (a string heading, no model)    /lessons/:slug
```

`Course` is a real navigable model (its page = hero + description + curriculum
grouped by `stage`). A course can be `status: coming_soon` (a specialization stub
shown "в разработке"). History: `Course` existed early, was flattened into
`Lesson#stage`, then re-introduced as a behaviour-bearing model once professions
needed depth — `stage` survives as the in-course section heading.

**Model invariants — don't "fix" these:**
- **`lessons.path_id` is a denormalized FK** (= `course.path`), kept in sync by
  `Lesson`'s `before_validation`. Hot queries join it directly; lessons never
  change course, so it can't drift. Not a `has_many :through`.
- **`lesson.position` is global within the profession** (not per-course) — keeps
  `prev_in_path`/`next_in_path` and "Продолжить" flowing across course boundaries
  while the lesson sidebar is scoped to the current course.
- **Destroy chain: Course owns lessons.** `Path → courses → lessons` are
  `dependent: :destroy`; `Path has_many :lessons` carries NO dependent option
  (else lessons destroy twice). Both `belongs_to` counter_cache.
- **Seed loader is create-only** (DB is the source of truth, not YAML). Walks
  `<path>/path.yml` → `<NN>-<course>/course.yml` →
  `<MM>-<section>/section.yml` (title → `stage`) → `<lesson>.md`; upserts
  idempotently, never overwrites human edits, assigns global position by walk
  order. **`Lesson.slug` is GLOBALLY unique** — the idempotent seed won't update
  an existing slug (destroy the path to re-seed).

**Routes (actual — see `config/routes.rb`):**
```ruby
root "paths#index"                                          # signed-in "/" → /dashboard
resource :session, only: [:new, :create, :destroy]          # login (Writebook pattern)
resources :users, only: [:new, :create]                     # registration
get "dashboard" => "dashboard#show"                         # "Моё обучение"
resources :paths, only: [:index, :show], param: :slug      # professions (show lists courses)
resources :courses, only: [:show], param: :slug            # course page (curriculum by stage)
resources :lessons, only: [:show], param: :slug do         # flat slug URLs
  resource :completion, controller: "lesson_completions"   # binary "mark as done" (Turbo Stream)
  resources :revisions, only: [:index, :show]              # reader-facing change history
  resources :suggestions, controller: "lesson_suggestions" # reader-submitted edits
end
namespace :admin do ... end                                # gated by can_edit_content? / can_administer?
```

**Models (actual — see `app/models/`):**
```
User (has_secure_password; role: member | editor | administrator; suspended_at;
      reminder_emails; progress helpers: completed?, started_paths, focus_path,
      next_lesson_in(path), activity_by_day)
  → has_many Sessions          (has_secure_token; signed permanent cookie)
  → has_many LessonCompletions (unique per user+lesson — binary progress, Odin-style)
  → has_many JournalEntries    (private, text-only work log)
Current (CurrentAttributes) + Authentication concern in ApplicationController:
  require_authentication by default; public controllers opt out via
  allow_unauthenticated_access (which still restores Current.user).

Path (profession)  author_id (nil = official); status: draft|pending_review|published;
                   locale (each language market gets its OWN paths — TOP model)
  → has_many Courses (status: draft|pending_review|published|coming_soon)
    → has_many Lessons (position global within path; grouped in view by #stage)
      → has_many Resources           (country_code: nil = universal)
      → has_many LessonSuggestions   (pending|approved|rejected)
      → has_many LessonRevisions     (immutable, append-only audit log)
  → has_many Lessons (denormalized path_id, for catalog-wide queries)

# Lesson body/description/task are ActionText rich text, with a plain-text
# markdown column as fallback. RevisionDiff (a PORO) renders word-level diffs.
# AdminAction = append-only log of people/moderation actions.
```

## Content format — every lesson follows this

1. **WHY** — the `description` field, also the page's `<meta name="description">`
   (≤160 chars). One self-contained sentence ≤155 chars that honestly answers
   *"why spend time on this"* AND opens with the topic in natural search phrasing
   (it does double duty: human motivation + SEO snippet). Don't keyword-stuff.
2. **OFFICIAL DOCUMENTS** — curated links, ranked (★ required, ○ optional).
3. **PRACTICAL TASK** — a concrete, verifiable assignment.

**Practice lessons (`kind: practice`)** add a `difficulty:` (beginner = paper/bench,
safe and ~free; intermediate = real tools; advanced = capstone) driving the
`/projects` grid, and a brief-format «## Задание»: **Цель** → **Понадобится**
(honest materials list + prices/free alternatives) → `> [!ОПАСНО]` block where the
work touches anything live → **Шаги** → **Что сдать** (→ journal entry) →
**Самопроверка** (verifiable yes/no vs the official standard). Эталоны:
`chtenie-shem-i-ugo.md`, `soedinenie-provodov.md`, `sborka-shchita.md`.

**Name de-facto-standard tools.** When a specific program is the industry standard
for a recurring task (Modbus Poll/qModMaster, UaExpert, Wireshark, the canonical
PLC IDE), name it and say briefly what it's for — don't hide behind "use a suitable
tool." Add it both as a `tool` resource and a `> [!СОВЕТ]` mention. This is about
the standard *tool for the task*, not vendor lock-in.

## Code rules (DHH / Basecamp style)

- **Follow Rails defaults.** No gems, patterns, or abstractions unless Rails
  genuinely can't do it. When in doubt, check how Basecamp/HEY would do it.
- **HTML-first.** Server-render everything. Turbo Frames for partial updates,
  Turbo Streams for real-time pushes. Stimulus only for behavior that needs JS.
- **ERB only.** No Haml, Slim, ViewComponent. Partials for reuse.
- **Skinny controllers, fat models.** Extract to concerns at ~200 lines. No
  service objects for simple CRUD. No `before_action` chain longer than 2.
- **RESTful routes.** 7 standard actions first; custom actions only when REST
  doesn't fit.
- **i18n from day one.** All user-facing strings via `I18n.t`. Russian first,
  keys in English.
- **Comments sparingly.** Make the code self-documenting first — clear names,
  small methods. Don't narrate *what* the code does. Add a *short* one-line
  comment only for a genuinely non-obvious *why*. A comment is unchecked prose
  that rots; every one you keep is a liability. Rationale that isn't needed to
  read the code goes in the commit message or `docs/`, not above the method.
- **Minitest + fixtures.** No RSpec, no FactoryBot. Test critical paths; don't
  test Rails itself. CSS-only changes can't break server rendering — verify
  visually, not with `bin/rails`. Re-render/test only when ERB, Ruby, or `.yml`
  change.

## Anti-patterns

- No React, Vue, or SPA. This is a Hotwire app.
- No Devise. Auth is `has_secure_password` + hand-rolled `SessionsController` +
  the `Current`/`Session` pattern (à la Writebook, in
  `concerns/authentication.rb`). Admin is the `role` enum — no second login
  mechanism, no HTTP Basic.
- No `respond_to` JSON/HTML unless a real consumer exists. No API-first design.
- **No Tailwind, `@apply`, `@theme`, `@layer`, `@import` between CSS files, no
  build step.** Propshaft serves CSS as-is; the browser handles the cascade via
  filename load order. No `tailwind.config.js` / `postcss.config.js` / JS asset
  tooling. No `dark:`/`sm:`/`lg:` prefixes — use `@media` inside the CSS. The app
  is black-first / single-theme; there is no light/dark switch.
- **Self-hosted web fonts only** — no Google Fonts, no CDN. Inter + Inter Tight in
  `app/assets/fonts/`, declared in `_fonts.css`. No other typefaces.
- No raw hex/rgb/hsl — colors come from OKLCH primitives in `colors.css`.
- No concerns until a model exceeds ~200 lines. Premature extraction is worse
  than duplication.

## UI — Canonical DHH style (Writebook canon)

Three reference codebases, each for a different layer — don't mix their roles:
- **Writebook** (`/home/pingvinus/dhh-references/writebook/`) — the **CSS/auth
  canon**: stylesheet layout, tokens, component-local variables, the
  `Session`/`Current` pattern. Its simplicity is the point.
- **Fizzy** (`/home/pingvinus/dhh-references/fizzy/`) — the **bigger-app
  Rails/Hotwire reference**: richer Turbo Stream patterns, filters, larger models.
- **The Odin Project** (github raw files) — the **product-mechanics reference**:
  completion, sidebar, dashboard. Copy mechanics, not its Rails style (it uses
  ViewComponents/Tailwind — we don't).

`app/assets/stylesheets/` mirrors Writebook's file layout 1-to-1 (`_reset.css`,
`base.css`, `colors.css`, `layout.css`, `utilities.css`, `buttons.css`,
`inputs.css`, `panels.css`, etc.) plus domain files. Propshaft emits one `<link>`
per file; cascade is filename-alphabetical (prefix bedrock with `_`).

- **Fonts:** `@font-face` in `_fonts.css`. `--font-sans` (Inter) for body/UI;
  `--font-display` (Inter Tight) for headings — declared in `base.css`. Largest
  titles are `font-weight: 800` + uppercase.
- **Color (`colors.css`):** OKLCH primitives in `:root` (`--lch-*`); semantic
  abstractions reference them via `oklch(var(--lch-*))` (`--color-bg`,
  `--color-ink`, `--color-link`, `--color-positive`/`-negative`, etc). **Any new
  colour is added as an OKLCH primitive here first.** Historical names hold dark
  values (`--lch-black` = near-white ink, `--lch-white` = pure-black bg).
- **Dark, black-first foundation — but usability comes first.** Single dark theme
  (`color-scheme: dark` only), no light mode. The guiding principle is **"make it
  maximally clear, convenient and intuitive for the user, using proven design
  patterns"** — not minimalism for its own sake. Monochrome + the blue
  `--color-link` is the calm default; most hierarchy comes from typography,
  weight, spacing, brightness. But **color is allowed where it genuinely helps**
  the user scan/categorize/signal state (e.g. resource-type badges:
  norm=red/book=teal/video=purple/article=yellow/tool=green in `badges.css`).
  When you add it: define an OKLCH primitive, reuse `.badge--*` patterns, never a
  one-off decorative hue.
- **Naming:** hyphenated-flat (`.btn`, `.panel`); `--modifier` for variants;
  `__element` only for a nested DOM piece. **Component-local CSS variables** for
  theming (each component declares its own `--btn-background` etc with defaults;
  modifiers override). **Spacing primitives** `--inline-space`/`--block-space`
  (+ `-half`/`-double`) in `utilities.css` — use these, not raw rem/px.
- **Containers:** `.container` (72rem) / `.container--reading` (56rem);
  `.section` / `.section--divided`. Body is a 3-row grid so the footer sticks.
- **Components:** `.panel` (card), `.btn` (outlined base; `--reversed` = filled
  primary, `--negative`/`--positive`, `--small`/`--large`), `.input`
  (`--mono`/`--textarea`), `.badge`. Hover/focus is centralized in `base.css`.
- **Icons:** Heroicons (via `heroicon` gem) for generic glyphs; **profession/topic
  icons** are self-hosted Tabler line SVGs inlined in `shared/icons/`, rendered by
  `topic_icon_svg(token)`, sized via parent CSS. Monochrome line-style only — never
  mix in third-party/PNG icons.
- **Flash:** `render "shared/flash"` — fixed Turbo Frame pill, auto-dismiss via
  the `element-removal` Stimulus controller. **Account menu:** signed-in header
  shows one name button opening a native `popover` hub (zero JS).

## Feature map

Each line is one shipped subsystem — see `docs/MVP.md` for the detailed "what
shipped" ledger and rationale, and git history for when.

- **Accounts & progress (v0.2):** registration/login, binary `LessonCompletion`
  ("Отметить пройденным" via Turbo Stream), per-stage/per-path progress bars,
  `/dashboard` with continue links, desktop two-column lesson layout.
- **Signup flow:** Fizzy pattern — email → emailed 6-char code (15 min) → name +
  password; state in encrypted session (`Signup` PORO, no table); User created
  only at the final step. **Production signup REQUIRES working SMTP.** Login stays
  password-based on purpose. Post-signup founder welcome letter (`<dialog>`).
- **Password reset:** `generates_token_for`, `PasswordsController` + mailer.
- **Editing pipeline:** signed-in readers *suggest* an edit to a lesson section
  (rate-limited + honeypot); an editor reviews; every applied change appends an
  immutable `LessonRevision`; reader-facing `/revisions`. Rollback = a new
  revision, never a rewrite.
- **Roles trust ladder:** `member` → `editor` («Эксперт», `can_edit_content?`) →
  `administrator` (`can_administer?`, `/admin/users`, can't change own role).
  `Editorship` join scopes editor rights to granted professions; only admins
  publish. First admin via `ADMIN_EMAIL`/`ADMIN_PASSWORD` seed.
- **Admin dashboard (`/admin`, admin-only):** signups + 12-week CSS bar chart,
  active-this-week, pending suggestions, completions, journal volume, content
  health, `SystemStatus` vitals (disk safety + SQLite footprint, Solid Queue
  health, `MailMetrics` 7-day mail flow). Plain group/count queries, no charting
  JS, no admin gems; scaling seam is `Rails.cache.fetch`.
- **Admin action log (`/admin/log`):** `AdminAction` append-only transparency log
  of people/moderation actions (role changes, grants, suggestion approve/reject,
  rollback, suspend) — second audit trail alongside `LessonRevision`. Immutable,
  denormalized `details` JSON, keyset pagination + category/actor filters (Fizzy
  feed pattern), no free-text search. Adopt wiki *data* mechanics (immutable
  history + transparency), NOT its social governance machine.
- **User detail card (`/admin/users/:id`):** profile + role/suspend controls,
  snapshot, progress, active sessions (force-logout data), recent activity.
- **User suspension:** `users.suspended_at`; `suspend!` revokes sessions and
  `User.active.authenticate_by` blocks login; reversible (`reinstate!`),
  self-suspend lockout guard. No durations/IP/partial blocks.
- **Practice journal + heatmap:** `JournalEntry` (`/journal`) — private,
  **text-only** work log (rich text + optional lesson link, rate-limited). The
  GitHub-style 16-week heatmap counts completions + journal entries. **No photo
  uploads** (see north star).
- **Focus direction:** `User#focus_path` (derived from latest completion, no
  stored setting) drives the dashboard hero, catalog banner, and `/projects` sort.
  Defaults, not walls — nothing is locked.
- **Contributor attribution:** muted "Статью улучшили" credit under each lesson,
  derived from `LessonRevision` (founder's direct edits store `editor_name: nil`,
  so he never appears). Generated-initials avatars (`AvatarsHelper`), no uploads.
- **Projects (`/projects`):** aggregator of all `kind: practice` lessons across
  published paths, with difficulty filters.
- **Calculators (`/calculators`):** trade formula tools — code registry (no DB) +
  one Stimulus controller for all math.
- **Retention email (the ONE):** `LearningReminderJob` (daily, Solid Queue
  recurring) nudges stalled learners once per stall — never a drip. Opt-out
  checkbox + tokenized one-click unsubscribe (RFC 8058). Don't add more
  lifecycle emails without an explicit founder decision.
- **Feedback line («Написать автору»):** async `Feedback` model → founder reads at
  `/admin/feedbacks` (unread badge) + email per message. NOT a chat.
- **Error monitoring (gem-free):** `ErrorSubscriber` on `Rails.error` emails
  administrators on unhandled exceptions (throttled via Solid Cache). No
  Sentry/Honeybadger — this + an external `/up` ping is the whole story.
- **Participation page (`/contribute`):** the open-project page, split from
  `/support_us` (money). Frames the open commons + multi-profession vision; this
  is the future-co-author surface where the wide vision is voiced.
- **Partners (`/partners`):** adaptive sponsors page (invitation while empty),
  curated constant, independence firewall.

## Recorded decisions — don't re-propose

- **No `docs/CONTINUITY.md`** (2026-06-22): even a secrets-free runbook is
  unwanted attack surface. Bus-factor mitigation lives out-of-band.
- **No realtime chat / floating widget:** a solo founder can't honor chat
  expectations; async feedback + honest SLA wins.
- **No leaderboard** for contributions: recognition (attribution), not
  competition — competition rewards gaming and repels experts.
- **No more uploads on `JournalEntry`** — and no re-adding media to any private
  model. If a public moderated portfolio ever ships (v0.3), media goes off-disk
  (object storage), never onto SQLite.
- **Monetization deferred** (June 2026): v0.4 certificates deferred; materials
  stay free/open forever; retention before revenue. Most promising path = B2B
  (training centers / employers). See `docs/VISION.md`.
- **Positioning: narrow wedge, wide ceiling.** Marketing copy speaks only about
  industrial trades that exist; the wider "any profession" vision lives on
  `/contribute`, the FAQ, and `/roadmap`. No renaming.
- **No command palette** until search ships (v0.3) — the palette is search's UI.
- **No wiki social governance** (arbitration, RfA voting, granular permission
  tiers, checkuser) — «лишние механики» at this scale.

**Not built yet (v0.3):** community-authored roadmaps, public profiles, search,
moderated public portfolio.

## Docs

- `docs/VISION.md` — what we're building, for whom, why (incl. business model)
- `docs/MVP.md` — phased rollout + the canonical "what shipped" status note
- `docs/DEPLOY.md` — first-deploy runbook (Kamal, SMTP, backups, monitoring)
- `docs/CONTENT_PROMPT.md` / `LESSON_DEEPEN_PROMPT.md` / `IMAGE_PROMPT.md` —
  reusable content-authoring prompts
- The public roadmap is the `/roadmap` page (`ru.yml → roadmap:`) — update it when
  shipping user-visible features
</content>
