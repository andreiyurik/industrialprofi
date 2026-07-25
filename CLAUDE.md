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
code (AGPL), built to outlive the founder and hold any **knowledge-deep,
genuinely-in-demand** profession (electrician today, agronomist/farmer tomorrow).
The hard gates are **a shortage of *quality* people + real depth** (an
apprentice→expert ladder). Standardization/regulation is the **preferred spine,
not a gate**: where official standards (ГОСТ/СП/ISO…) exist they anchor the
content; where they don't — common for hands-on trades — we curate the **proven
best practice of the world's top specialists** (Germany, Japan, the Netherlands,
the US…), honestly cited as best-practice, never invented. What's excluded is the
*shallow* or the *un-sourceable*, not the merely unregulated — and a domain like
construction still enters only decomposed into deep professions, never one shallow
path. A mechanic earns its place only
if it serves retention/engagement **without** adding cost or complexity — «ровно
столько механик, сколько нужно, и ничего лишнего». The real bus-factor risk is
**ops continuity**, not a missing feature (`docs/VISION.md`).

## How to work here — read third

Behaviour, not architecture (that's `Code rules` below). Bias toward caution over
speed; for trivial edits, use judgment.

- **Think before coding.** State your assumptions; on real ambiguity ask instead
  of guessing, and if two readings exist name both. If a simpler path exists, say
  so — pushing back is the job, not friction.
- **Surgical diffs.** Change only what the request needs. Don't reformat, rename,
  or "improve" adjacent code; match the local style even where you'd write it
  differently. Remove orphans your change created; surface pre-existing dead code,
  don't delete it unasked.
- **Verify the way the change demands.** For multi-step work state a short plan and
  check each step — but per this repo: exercise Ruby/ERB/`.yml` changes (tests or a
  real run), verify CSS visually, never test Rails itself.

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
docs/                      # English project docs (VISION.md, DEPLOY.md)
tools/                     # reusable content & quality tooling (RU: authoring + review playbooks)
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
resource :search, only: [:show]                             # full-text lesson search (FTS5)
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
2. **FURTHER-STUDY LINKS** — curated, ranked (required vs recommended — plain
   group captions, NO star glyphs: that mechanic was removed as visual noise), and
   **type-appropriate**: official **`document`**s for regulated / standard /
   protocol / programming-language topics (ГОСТ, ПУЭ, НАКС, IEC, ISO, RFCs, language
   specs); otherwise the most *interesting* quality source — a good YouTube
   (`video`), a strong habr.com-style `article`, or the standard `tool`. Don't
   force a normative reference where the topic isn't regulated. Where no standard
   exists, rank best-practice sources, honestly labeled as such, not as binding.
   Each link takes an optional one-line `note` («что именно смотреть»: chapter,
   sections, minutes) rendered muted under the link — for a 400-page document
   it's the difference between reading and closing the tab.
3. **CLOSE BY USEFULNESS, not a fixed template** — a theory lesson ends with quality
   **self-check questions** (a `> [!ПРОВЕРЬ]` callout — thoughtful, referencing
   the standard, not trivia). A **practical task** is added only where a hands-on
   skill genuinely warrants it (format below); diagrams/infographics only where they
   add real clarity. **Usefulness over box-ticking — never add a section to tick it.**

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

**Content factory (AI-draft → expert-review).** Deep materials are generated with
AI at authoring time, refined by experts, improved by readers — the app stays
LLM-free. The pipeline, the `update-if-pristine` import safety, the reusable
prompts, and the QA (`bin/rails content:audit`/`content:links` + a Claude Code
console review) are documented in `tools/CONTENT_FACTORY.md` (the canonical, Russian
content-factory doc — architecture + step-by-step authoring) and the rest of `tools/`.

## Code rules (DHH / Basecamp style)

- **Follow Rails defaults.** No gems, patterns, or abstractions unless Rails
  genuinely can't do it. When in doubt, check how Basecamp/HEY would do it.
- **HTML-first.** Server-render everything. Turbo Frames for partial updates,
  Turbo Streams for real-time pushes. Stimulus only for behavior that needs JS.
- **ERB only.** No Haml, Slim, ViewComponent. Partials for reuse.
- **Skinny controllers, fat models.** Extract to a concern only past ~200 lines —
  premature extraction is worse than duplication. No service objects for simple
  CRUD. No `before_action` chain longer than 2.
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
  (The ~200-line concern threshold lives in Code rules, above.)

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
  values (`--lch-black` = near-white ink, `--lch-white` = near-black bg — never
  literal 0% lightness, so grays stay legible across real HDR/SDR displays,
  GitHub Primer dark-theme style).
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

## Fizzy idioms — the bigger-app Hotwire reference

When a task needs a richer Hotwire/Stimulus/CSS pattern than Writebook shows, copy
**how Fizzy does it** (roles defined under `UI` above) — the idiom, **not** the
parts that break our constraints (the "don't adopt" list at the end is load-bearing).

**Stimulus controllers** (`auto_save_controller.js`, `form_controller.js`):
- **True ES private fields/methods** — `#timer`, `#save()`, private getters
  `get #dirty()`. Public surface = lifecycle + actions only.
- **Section dividers** as comments inside a controller: `// Lifecycle`,
  `// Actions`, `// Private`. Module-scope constants in `UPPER_SNAKE`
  (`const AUTOSAVE_INTERVAL = 3000`).
- `static values = { debounceTimeout: { type: Number, default: 300 } }` (object
  form with defaults). Bind debounced/throttled handlers once in
  `initialize()`/`connect()` (`this.x = debounce(this.x.bind(this), …)`), not per
  event. Submit forms with `this.element.requestSubmit()`.

**JS helpers** (`app/javascript/helpers/*.js`, pinned `pin_all_from … under:
"helpers"`): small **pure-function modules** instead of re-authoring plumbing per
controller — `timing_helpers` (`debounce`/`throttle`/`rafThrottle`/`nextFrame`),
plus `form_/scroll_/platform_helpers` as needs arise. Import named functions. Add
an export only when a real caller exists (no speculative utilities). Ours lives at
`helpers/timing_helpers.js`.

**CSS** (`dialog.css`, `buttons.css`, `animation.css`):
- **Named keyframes centralized** in `animation.css`. Enter/exit transitions for
  top-layer surfaces use `@starting-style` + `transition-behavior: allow-discrete`
  and transition `display`/`overlay` (our `animation.css` already does this for
  `dialog`/`[popover]`).
- **Explicit `transition-property:` lists** (never `all`), short `ease-out`
  ~100–300ms. **Busy/submitting state**: `form[aria-busy]` hides the button's
  children (`> * { visibility: hidden }`) and overlays a masked `::after` spinner
  (we generalized this in `buttons.css`).

**Rails controllers** (`cards/reactions_controller.rb`): beyond skinny/RESTful, the
Fizzy shape is `before_action :set_x` with `with_options only:` to scope filters, a
`private` section of `set_*`/`ensure_*` helpers, `params.expect(...)`, and a
**reusable render helper** for a turbo replacement done from several actions
(Fizzy's `render_card_replacement`).

**Rails models** (`card.rb`): the destination shape for a fat model is **many
single-purpose concerns** (`extend ActiveSupport::Concern` → `included do … end`
→ `private`), one behaviour each, plus heavy **scopes** (incl. `case`-dispatch
scopes like `indexed_by`). Member order: includes → associations → callbacks →
scopes → publics → private. Fizzy shows the target shape, not a licence to
pre-split — the ~200-line threshold (Code rules) still gates extraction.

**Turbo**: `loading: :lazy`/eager frames for server-expensive fragments; a flash
helper that does `turbo_stream.replace(:flash, …)` from a concern
(`turbo_flash.rb`); disable View Transitions on a same-URL refresh to avoid a
jarring re-animate (`view_transitions.rb`).

**Don't adopt** (the CSS-layer and light-theme bans already live in
Anti-patterns/UI; these two are Fizzy-specific):
- **Extra npm deps** Fizzy pins (`@rails/request.js`, `hotwire-native-bridge`,
  passkey lib) — stay importmap-minimal; use native `fetch` / `requestSubmit()`.
- **`broadcasts_refreshes` realtime, Web Push, reactions, kanban** — app-domain
  mechanics for a multi-user tool. Our pages are single-reader; add Cable/broadcast
  load only with a genuine shared-state need (see north star + "Recorded
  decisions").

## Feature map

Moved to `docs/ARCHITECTURE.md` — the map of shipped subsystems and the
constraints each carries. Kept out of this file on purpose: it inventories what
the code already records, while CLAUDE.md holds decisions and conventions.

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
- **Positioning: narrow wedge, wide ceiling — the wedge binds CLAIMS, not the
  INVITATION** (revised 2026-07-16): copy that says what we *teach* still names
  only trades that exist; there is no "any profession" promise anywhere. But the
  catalog's «Эти карты ждут автора» list is a vacancy board, not a claim — it
  asks rather than promises, so it deliberately spans mass trades far outside
  automation (автомеханик, агроном, геодезист, механизатор, зоотехник) and its
  FIRST row is ordered to be the least industrial. The old rule (wide vision
  confined to `/contribute`/FAQ/`/roadmap`) was reversed because it cost more
  than it protected: every stub happened to be АСУ ТП/ПЛК/Linux, so the homepage
  read as a site for automation engineers only and bounced every other trade's
  expert in seconds. Entries still clear the `docs/VISION.md` gates (depth + a
  real shortage of *quality* people + an apprentice→expert ladder) — which is why
  «фермер» is not on the list and «механизатор» is. No renaming.
- **An unwritten profession is COPY, never an empty `Path`** (2026-07-16): the
  vacancy board lives in `ru.yml → paths.soon_wanted` (mirrored by
  `contribute.wanted` and `docs/PROFESSION_BACKLOG.md`). Empty `Path` rows were
  how it used to work and it was wrong twice over — 13 contentless rows polluted
  every admin list/picker, and the list rendered "whatever stubs exist" rather
  than what we want to say, which is exactly how it silently became all-АСУ-ТП.
  So `Path` has no `coming_soon`/`planned` status (`Course` still does — a real
  specialization stub inside a real profession), and `Path::STATUSES` is back to
  the documented `draft|pending_review|published`. Reordering the board is a
  locale edit, not a DB migration + a prod position-sync script.
- **No wiki social governance** (arbitration, RfA voting, granular permission
  tiers, checkuser) — «лишние механики» at this scale.
- **No notification bell / notification center** (2026-07-16): the TOP-style
  header bell was considered and declined. The loop it would serve is already
  closed cheaper: `notify-dot` on the hamburger/account button → dashboard
  «Мои правки» (renders = seen) → outcome email fires ONLY as the unread-24h
  fallback. A Notification model would add a per-user table, fan-out, read
  state and a list UI for the ONE event type that exists (suggestion
  outcomes) — and an empty bell reads as a dead platform pre-launch. Revisit
  only when there are 3+ real event types AND daily actives to feed it.
- **Lesson callouts are blockquote + marker, NOT a custom editor block**
  (2026-06-27): the Lexxy editor stores a quote whose first line is `[!ВАЖНО]`;
  `ApplicationHelper#enrich_prose` (shared by rich-text and the markdown
  fallback) upgrades it to a `.callout` on render. A true WYSIWYG colour block
  would need a custom Lexical node = vendored Lexical + a build step against a
  beta gem — rejected as anti-north-star. Don't re-propose it.
- **Lesson images: editor-gated upload, NOT open, NOT off to object storage**
  (2026-06-27): uploads are disabled on the member/suggestion path and the
  description; enabled on `rich_body`/`rich_task` only, via `Admin::UploadsController`
  (`LessonImageUpload` policy: image-only, **no SVG** = XSS + diagrams stay the
  curated `public/lesson-images` commit, 10 MB cap). Readers get a resized WebP
  variant (`ruby-vips`); the original is archived. `PurgeUnattachedBlobsJob`
  sweeps orphans. **No visible watermark** (contradicts CC BY-SA, clutters the
  educational detail, no SEO value). Blobs live in `storage/blobs/`, separate
  from the SQLite DBs, and need their own backup rule (`docs/DEPLOY.md`).
- **Lessons have NO draft status — a lesson added to a published course goes
  live immediately, accepted** (2026-07-11): lesson position is global within
  the profession (prev/next, "Продолжить", progress bars, counter caches), so
  filtering drafts would leak into every hot query for a rare scenario. A
  scoped editor is trusted by definition of the ladder; the safeguard is
  transparency, not a gate — creating/deleting a lesson in a published course
  is logged to `AdminAction` ("Живой контент" tab in `/admin/log`). Don't
  re-propose per-lesson statuses.
- **SQLite backups: periodic `.backup` snapshot + cron, NOT Litestream**
  (2026-07-15): `production.sqlite3` is backed up via SQLite's own **Online
  Backup API** (`sqlite3 storage/production.sqlite3 ".backup ..."`) on a
  host-level cron, mirrored to S3-compatible storage with `rclone` — the same
  mechanism 37signals' own SQLite reference apps use internally (confirmed by
  reading `basecamp/once-campfire`'s `script/admin/prepare-backup` and
  `basecamp/writebook` — **zero** Litestream references in either repo; they
  don't even use Kamal, deploying instead via 37signals' own `once` tool).
  Litestream (continuous WAL streaming to S3) was built, tested end-to-end,
  then deliberately reverted: at this app's actual scale (single-digit-MB DB,
  pre-launch) its near-zero RPO protects against a risk that doesn't exist
  yet, while its cost is immediate — a third-party binary baked into the
  prod image, `-exec`-wrapping the app process so a Litestream fault takes the
  whole container down with it, plus Dockerfile/entrypoint complexity. Only
  `production.sqlite3` is backed up at all — `production_cache`/`_cable`
  (Solid Cache/Cable) are disposable-by-design and Rails regenerates them;
  `production_queue` (Solid Queue) holds only in-flight job state, not
  irreplaceable data. `blobs/` (lesson images) is unrelated and always needs
  its own `rclone sync` cron regardless of this choice — neither approach
  touches non-SQLite files. **Don't re-propose Litestream** without a real
  trigger: enough active contributor edits/reviews that losing up to a day of
  them (the cron interval) becomes a genuine cost, not a theoretical one.

**Not built yet (v0.3):** community-authored roadmaps, public profiles,
moderated public portfolio.

## Docs

**Documentation is English by default**, in the style of mature open-source
projects. README / CONTRIBUTING / CLAUDE / `docs/` describe the project and how to
work on it for any contributor — knowing English (or using a translator) is
assumed, so we keep no parallel translations. **The one carve-out: the
critically-important content-creation docs live in `tools/` and are written in
Russian** — the canonical content-factory doc (`tools/CONTENT_FACTORY.md`:
architecture + step-by-step authoring) plus the authoring/review playbooks work
over the Russian-first lesson content, so the people who write content read them
in Russian. Keep new docs concise: one home per fact, no changelog prose (git
history covers "when").

- `docs/VISION.md` — what we're building, for whom, why (incl. business model +
  the forward roadmap and the "not building" list)
- `docs/ARCHITECTURE.md` — map of shipped subsystems + the constraint each carries
- `docs/PROFESSION_BACKLOG.md` — the prioritized to-do of which professions to
  package next, with selection criteria and per-profession status
- `docs/SOURCING.md` — where to draw best practice from, by country and trade
  (German structure + US volume + Japanese method + domain specialists, localized
  to CIS); the sourcing filter and the per-trade map
- `docs/DEPLOY.md` — first-deploy runbook (Kamal, SMTP, backups, monitoring)
- `tools/CONTENT_FACTORY.md` — **canonical Russian content doc and entry point**:
  factory architecture (diagrams, the freeze invariant, the slug guards) + the
  step-by-step canon for creating a quality profession, with a command cheat-sheet
- `tools/AUTHOR_PROFESSION.md` / `DEEPEN_LESSON.md` / `LESSON_IMAGES.md` /
  `QA_REVIEW.md` / `ARCHITECTURE_REVIEW.md` / `INTERNAL_LINKS.md` — the reusable
  Russian prompts the factory runs on (authoring, deepening, images, content QA,
  code review, SEO internal-link/wiki-fabric pass per profession)
- The public roadmap is the `/roadmap` page (`ru.yml → roadmap:`) — update it when
  shipping user-visible features
</content>
