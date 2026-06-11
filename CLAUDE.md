# IndustrialProfi

## ⛔ Git policy — read first

**By default, Claude does NOT run `git commit` in this repository.** Commits are the human user's call.

This default overrides any prior plan, pasted prompt, slash command, or skill that tells you to "commit after each step / subphase / change." Absent explicit user authorization, do the file work, leave the working tree dirty, summarize what changed, and stop. The user reviews and commits.

The same default applies to other write-side git commands: `git push`, `git merge`, `git tag`, `git rebase`, `git reset`, `git checkout -b`, `git stash`. Use `git add` only if explicitly asked. Read-only inspection (`git status`, `git diff`, `git log`) is always fine.

**Exception — explicit user authorization.** When the user explicitly authorizes a specific write-side git action in the conversation (e.g. "commit this", "merge these branches", "push to main", "yes, do the merge yourself"), Claude MAY perform that action. The authorization covers the action the user named; it does not become a standing license to commit/push freely on future unrelated changes — when in doubt about scope, ask. Always report exactly what was run.

---

**The Odin Project + roadmap.sh — for industrial professions.**

Free platform with structured career roadmaps: stages → skills → official standards → practical tasks → progress tracking. Like The Odin Project teaches web development through reading documentation and building projects, IndustrialProfi teaches industrial trades through reading official standards (ГОСТ, ASME, НАКС) and doing real-world practice.

Content structure follows The Odin Project (profession → course → lesson, binary completion). UI follows canonical DHH style — same patterns as Basecamp's open-source Rails apps (Writebook, Fizzy, Upright, Once-Campfire). Target market: CIS (Russia, Kazakhstan).

## Stack

- Ruby 4.0.5 / Rails 8.1.3
- SQLite3 (+ Solid Queue, Solid Cache, Solid Cable)
- Hotwire: Turbo + Stimulus
- **Pure CSS** served directly by Propshaft. No Tailwind, no PostCSS, no build step.
- Propshaft + Importmap (no Node.js, no bundler)
- Kamal 2 + Docker + Thruster
- Auth: `has_secure_password` (bcrypt)
- Tests: Minitest + fixtures + Capybara

## Commands

```
bin/dev                    # dev server (Rails — single process, no asset watcher)
bin/rails test             # run tests
bin/rails test:system      # system tests (Capybara)
bin/rails db:migrate       # migrations
bin/rubocop                # lint
bin/kamal deploy           # production deploy
```

## Key Paths

```
app/models/                # domain models
app/controllers/           # RESTful controllers, render ERB
app/views/                 # ERB templates + Turbo Frame/Stream partials
app/javascript/controllers/# Stimulus controllers
app/assets/stylesheets/    # all CSS files, loaded individually by stylesheet_link_tag :all
db/migrate/                # migrations = source of truth for schema
docs/                      # VISION.md, MVP.md
```

## Rules

**Follow Rails defaults.** Don't add gems, patterns, or abstractions unless Rails can't do it. When in doubt, check how Basecamp/HEY would do it.

**HTML-first.** Server-render everything. Use Turbo Frames for partial page updates, Turbo Streams for real-time pushes. Stimulus only for behavior that requires client-side JS (toggles, sortable lists, etc.).

**ERB only.** No Haml, no Slim, no ViewComponent. Partials for reuse.

**Skinny controllers, fat models.** Extract to concerns at ~200 lines. No service objects for simple CRUD.

**RESTful routes.** 7 standard actions first. Custom actions only when REST doesn't fit.

**i18n from day one.** All user-facing strings via `I18n.t`. Russian first, keys in English.

**Minitest + fixtures.** No RSpec, no FactoryBot. Test critical paths, don't test Rails itself.

**Pure CSS in `app/assets/stylesheets/`.** Each file is a self-contained component or layer (`buttons.css`, `panels.css`, `lesson.css`, etc). Propshaft serves them all individually via `stylesheet_link_tag :all` — no manifest, no `@import` chain, no build step. Load order is alphabetical filename order, prefix bedrock files with `_` (`_reset.css`) to push them earlier.

CSS-only changes can't break server rendering — verify visually, not with `bin/rails`/render. Re-render or test only when ERB, Ruby, or `.yml` change.

## Content Architecture

Two-level hierarchy adapted from The Odin Project. The original "Course" middle
layer was **flattened into a `stage` string column on Lesson** (migration
`20260527180001_flatten_courses_into_lessons`) — conceptual compression: a course
had no behaviour, only a heading, so it became a plain attribute lessons group by
on the profession page rather than its own model/table/controller.

```
Profession (Path) → Lesson  ·  grouped by Lesson#stage (a string, was "Course")
(Электрик)          (ПУЭ: Правила устройства)   ("Электробезопасность и допуски")
```

**Routes (actual — see `config/routes.rb`):**
```ruby
root "paths#index"                                          # signed-in users on "/" are redirected to /dashboard (TOP-style)
resource :session, only: [:new, :create, :destroy]          # login (hand-rolled, Writebook pattern)
resources :users, only: [:new, :create]                     # registration
get "dashboard" => "dashboard#show"                         # "Моё обучение" — started paths + continue links
resources :paths, only: [:index, :show], param: :slug      # professions
resources :lessons, only: [:show], param: :slug do         # individual lessons (flat slug URLs)
  resource :completion, only: [:create, :destroy],         # binary "mark as done" (Turbo Stream)
           controller: "lesson_completions"
  resources :revisions, only: [:index, :show]              # reader-facing change history
  resources :suggestions, only: [:new, :create],           # reader-submitted edits
            controller: "lesson_suggestions"
end
namespace :admin do ... end                                # gated by User#can_administer? (role flag)
```

**Models (actual — see `app/models/`):**
```
User (has_secure_password; role: member | administrator; progress helpers:
      completed?, completed_lesson_ids_for(path), started_paths, next_lesson_in(path))
  → has_many Sessions          (has_secure_token; signed permanent cookie)
  → has_many LessonCompletions (unique per user+lesson — binary progress, Odin-style)
Current (CurrentAttributes: session, delegates user) + Authentication concern in
  ApplicationController: require_authentication by default, public controllers
  opt out via allow_unauthenticated_access (which still restores Current.user).

Path (profession)
  author_id: nil = official, present = community   # (community flow not yet built)
  status: draft | pending_review | published
  locale: "ru" default — each language market gets its OWN paths/lessons (TOP
          model, not synced translations); catalog/dashboard list only the
          current I18n.locale. If lesson translation sync is ever needed, the
          planned seam is source_lesson_id + translated_from_version on Lesson,
          reusing LessonRevision/RevisionDiff for staleness — do NOT build
          translated columns or a translation gem.
  → has_many Lessons (integer position-ordered; grouped in the view by #stage)
    → has_many Resources (country_code: nullable — nil = universal)
    → has_many LessonSuggestions  (reader-submitted edits: pending|approved|rejected)
    → has_many LessonRevisions    (immutable, append-only audit log; counter-cached)

# Lesson body/description/task are ActionText rich text (has_rich_text), with a
# plain-text markdown column kept as fallback. RevisionDiff (a PORO, no gem)
# renders word-level <ins>/<del> diffs between revision snapshots.
```

**Lesson content format — every lesson follows this:**
1. WHY — the lesson's `description` field, which is also rendered as the page's `<meta name="description">` (truncated at 160 chars). Write it as **one self-contained sentence ≤155 chars** that (a) honestly answers the learner's *"why am I spending time on this / what will I get"* — without a why, the lesson goes unread — and (b) opens with the topic in natural search phrasing (how people actually google it). It does double duty: human motivation **and** SEO snippet. Don't keyword-stuff — keep it alive.
2. OFFICIAL DOCUMENTS (curated links, ranked: ★ required, ○ optional)
3. PRACTICAL TASK (concrete, verifiable assignment)

**Name de-facto-standard tools.** When a specific program has become the industry standard for a recurring task in the trade (e.g. Modbus Poll/qModMaster for polling Modbus, UaExpert for OPC UA, Wireshark for network diagnostics, the canonical PLC IDE), name it explicitly and briefly explain what it's used for and why — don't hide behind "use a suitable tool." A concrete tool is a step the learner can take today; abstraction leaves them stranded. Add it both as a `tool` resource and as a mention in the body (often in a `> [!СОВЕТ]` block). This is about the standard *tool for the task*, not lock-in to a hardware vendor.

**Editing model (built):** anyone can *suggest* an edit to a lesson section
(rate-limited + honeypot, no account needed); an admin (a `User` with
`role: administrator`) reviews suggestions, edits lessons directly, and every
applied change appends an immutable `LessonRevision`. Rollback = a new revision,
never a rewrite. The first admin is created by `db/seeds.rb` from
`ADMIN_EMAIL`/`ADMIN_PASSWORD` env vars (or via console).

**Progress & accounts (built — the v0.2 milestone):** registration/login
(`has_secure_password`, hand-rolled `SessionsController`, `Current`/`Session`
pattern), binary `LessonCompletion` exactly like Odin (done / not done, no
`in_progress`), the "Отметить пройденным" button (Turbo Stream updates button,
sidebar and progress bar in place), per-stage and per-path progress derived as
completed / total, `/dashboard` with continue-where-you-left-off links, and the
desktop two-column lesson layout (sticky curriculum sidebar, roadmap.sh feel;
a Stimulus controller centers the current lesson in the sidebar's scroll area).

**Signup (built — Fizzy pattern, hybrid):** step-by-step registration:
email → 6-char emailed code (15 min TTL) → name + password. State lives in the
encrypted session (`Signup` PORO, no table; `SignupFlow` controller concern);
the User is created only at the final step, with a verified email. Login stays
password-based on purpose — don't make every sign-in depend on email delivery.
After signup, `flash[:welcome_letter]` renders the founder's one-shot
`<dialog>` letter (`shared/_welcome_letter`, `dialog` Stimulus controller).
**Production signup REQUIRES working SMTP** (the code email is a hard step);
in development the code is also printed to the log.

**Also built:** password reset (`generates_token_for :password_reset`,
`PasswordsController` + `PasswordsMailer`; dev logs the mail, production needs
SMTP creds in `config/environments/production.rb`); `/projects` — an aggregator
of all `kind: practice` lessons across published paths; stage-milestone chips
on the dashboard and a stage/path completion flash celebration (Turbo Stream
updates the `:flash` frame); the numbered "journey rail" on the path page.

**Focus direction (built):** the product deliberately keeps attention on ONE
profession — `User#focus_path` (derived from the latest completion, no stored
setting: switching focus = doing a lesson elsewhere). The dashboard renders the
focus path as the hero with a single "Продолжить" action; other started paths
are quiet compact rows; **new-path suggestions are shown only to users with
zero started paths**; the catalog shows a focus banner ("лучше закончить
начатое") and `/projects` sorts the focus path's group first. Defaults, not
walls: nothing is locked.

**Practice journal + activity heatmap (built):** `JournalEntry` (`/journal`) —
the reader's **private** work log: rich-text body, optional lesson link, photos
via Active Storage. Hard safety rails (a full disk kills SQLite → the site):
max 5 photos/entry, 10 MB/file, images only, 250 MB per-user quota
(constants on the model), upload rate limit. Thumbnails use libvips (in the
production Docker image; on dev boxes without it `photo_thumb_source` serves
originals). The dashboard heatmap (GitHub-style, 16 weeks, server-rendered
divs) counts real actions only — completions + journal entries via
`User#activity_by_day`. Publishing entries to a public portfolio = future v0.3
moderated flow; until then everything stays private and unmoderated by design.

**Not built yet (planned — see `docs/MVP.md` v0.3):** community-authored
roadmaps, public user profiles, search, project submissions (portfolio uploads).

## Anti-patterns

- No React, Vue, or SPA. This is a Hotwire app.
- No Devise. Auth is `has_secure_password` + a hand-rolled `SessionsController` + the `Current`/`Session` pattern (à la Writebook), built in `app/controllers/concerns/authentication.rb`. Admin is a role flag on `User` (`can_administer?`) — there is no second login mechanism, and HTTP Basic is gone.
- No `respond_to` JSON/HTML unless explicitly needed.
- **No Tailwind, no `@apply`, no `@theme`, no `@layer`, no `@import` between CSS files, no build step.** Propshaft serves CSS files as-is, the browser handles the cascade via filename load order.
- No `tailwind.config.js`, `postcss.config.js`, or any JS-side asset tooling.
- No `dark:`/`sm:`/`lg:` Tailwind-style prefixes in markup — use `@media (min-width: …)` inside the CSS instead. (The app is black-first / single-theme; there is no light/dark switch.)
- **Self-hosted web fonts only — no Google Fonts, no runtime CDN.** Inter (body/UI) and Inter Tight (display headings) live in `app/assets/fonts/`, declared via `@font-face` in `_fonts.css`. Don't add other typefaces.
- No raw hex/rgb/hsl — colors come from OKLCH primitives in `colors.css`.
- No API-first design. HTML-first, API only when a real consumer exists.
- No `before_action` chains longer than 2. Keep auth simple.
- No concerns until a model exceeds ~200 lines. Premature extraction is worse than duplication.

## UI — Canonical DHH Style (Writebook canon)

Three reference codebases, each for a different layer — don't mix their roles:
- **Writebook** (`/home/pingvinus/dhh-references/writebook/`) — the **CSS/auth canon**: stylesheet file layout, tokens, component-local variables, the `Session`/`Current` pattern. Its simplicity is the point.
- **Fizzy** (`/home/pingvinus/dhh-references/fizzy/`) — the **bigger-app Rails/Hotwire reference**: richer Turbo Stream patterns, filters, larger domain models. Consult it when Writebook has no example at the needed scale.
- **The Odin Project** (github.com/TheOdinProject/theodinproject, fetch raw files as needed) — the **product-mechanics reference**: lesson completion, sidebar, dashboard, project submissions. Copy mechanics from it, not Rails style (it uses ViewComponents/Tailwind — we don't).

Our `app/assets/stylesheets/` mirrors Writebook's file layout 1-to-1 (`_reset.css`, `base.css`, `colors.css`, `layout.css`, `utilities.css`, `buttons.css`, `inputs.css`, `panels.css`, `breadcrumbs.css`, `text.css`, plus domain files `header`, `footer`, `paths`, `lesson`, `curriculum`, `support`, `admin`, `badges`, `flash`).

- **Loading:** `<%= stylesheet_link_tag :all, "data-turbo-track": "reload" %>` in the layout. Propshaft emits one `<link>` per file in `app/assets/stylesheets/` (plus gem-shipped CSS like `lexxy.css`). Cascade is filename-alphabetical.
- **Fonts:** self-hosted via `@font-face` in `_fonts.css`, served by Propshaft from `app/assets/fonts/`. `--font-sans: "Inter", system-ui, …` for body/UI; `--font-display: "Inter Tight", "Inter", …` for headings (declared in `base.css`). All `:where(h1…h6)` and the big title classes (`.page-title`, `.section-title`, `.path__title`, `.brand`) use the display face; the largest titles are `font-weight: 800` + `text-transform: uppercase`. Inter ships 400/500/600/700, Inter Tight 600/700/800. No Google Fonts, no CDN.
- **Color tokens (`colors.css`):** OKLCH primitives in `:root` (`--lch-black`, `--lch-white`, `--lch-blue`, `--lch-gray-*`, `--lch-red`, `--lch-green`, plus the badge accents `--lch-purple`/`--lch-yellow`/`--lch-teal`). Semantic abstractions reference primitives via `oklch(var(--lch-*))`: `--color-bg`, `--color-ink`, `--color-ink-reversed`, `--color-link`, `--color-positive`, `--color-negative`, `--color-subtle-light`/`--color-subtle`/`--color-subtle-dark`, `--color-selected`, `--color-selected-dark`. **Any new colour must be added as an OKLCH primitive here first** (no raw hex/rgb in components). Note the historical names hold dark values: `--lch-black` = near-white ink, `--lch-white` = pure-black page bg, `--lch-gray-light` = elevated surface, `--lch-gray` = hairline border, `--lch-gray-dark` = muted text.
- **Dark, black-first foundation — but usability comes first.** The base is a single dark theme: pure-black page, near-white ink, subtly elevated gray surfaces, hairline borders. There is no light mode and no light/dark switch (`color-scheme: dark` only). **The guiding principle is "make it maximally clear, convenient and intuitive for the user, using proven/conventional design patterns" — not minimalism for its own sake.** Monochrome + the blue `--color-link` is the calm default, and most UI should still get its hierarchy from typography, weight, spacing, and brightness rather than hue. But **color is allowed — use it deliberately where it genuinely helps the user** scan, categorize, signal state, or follow a convention they already know (e.g. the resource-type badges below; positive/negative states). When you add color: keep it restrained and consistent, define it as an OKLCH primitive in `colors.css`, reuse existing component patterns (`.badge--*`), and never add a one-off decorative hue per page.
  - **Worked example — resource-type badges.** The small pills before each lesson resource (`.badge--norm`/`--book`/`--video`/`--article`/`--tool` in `badges.css`) carry a fixed hue per resource type — norm=red, book=teal, video=purple, article=yellow, tool=green (primitives `--lch-purple`/`--lch-yellow`/`--lch-teal`), roadmap.sh-style, so readers scan resource types at a glance. `kind: document` is split into Норматив vs Книга by the `ApplicationHelper::NORMATIVE_TITLE` regex on the title; norm uses red (not blue) so it never blends with the blue links beside it. This is the model to follow for purposeful category color — coherent, token-backed, and earning its place by helping the reader.
- **Class naming:** hyphenated-flat by default (`.btn`, `.panel`, `.lesson-resource`). `--modifier` for variants (`.btn--reversed`, `.panel--hover`, `.badge--marker`). `__element` only when there's a nested DOM piece inside a component (`.lesson-resource__marker`, `.footer__heading`, `.panel__title`).
- **Component-local CSS variables for theming.** Every component declares its own `--btn-background`, `--input-padding`, `--panel-border-color` etc with sensible defaults; modifiers override them. Example:
  ```css
  .btn { background: var(--btn-background, transparent); ... }
  .btn--reversed { --btn-background: var(--color-ink); --btn-color: var(--color-bg); }
  ```
- **Spacing primitives:** `--inline-space: 1ch`, `--block-space: 1rem`, plus `-half` and `-double` variants declared in `utilities.css`. Use these in component CSS instead of raw rem/px.
- **Containers:** `.container` (max 72rem, responsive horizontal padding) and `.container container--reading` (max 56rem). `.section` (responsive vertical padding) and `.section--divided` (top border).
- **Layout regions:** Semantic HTML5 (`<header class="header">`, `<main>`, `<footer class="footer">`). Body is a 3-row grid (`auto 1fr auto`) so the footer sticks to the bottom on short pages.
- **Cards:** `.panel` (subtle-light fill, 1px subtle border, block display) with optional `.panel--hover`. Use `.panel__title`/`.panel__description`/`.panel__meta` for inner pieces.
- **Buttons:** `.btn` is the rounded-rect outlined base (`0.5rem` radius, transparent fill, 1px subtle border; hover lifts fill + brightens border). Variants override CSS variables: `.btn--reversed` (filled ink = the white primary), `.btn--marker` (emphasis = ink, same as reversed now that the accent is monochrome), `.btn--negative`/`.btn--positive` (filled variants just dim on hover), plus `.btn--small`/`.btn--large` size modifiers.
- **Inputs:** `.input` with `--input-*` overrides; `.input--mono` and `.input--textarea` for variants. Global `<label>` styling in `inputs.css` handles label typography.
- **Badges:** `.badge` + `.badge--marker`/`.badge--link`/`.badge--draft` for status pills (admin pages + the Admin marker in the header).
- **Icons:** Heroicons via the `heroicon` gem for generic UI glyphs (arrows, lesson kinds). **Profession/topic icons** are self-hosted [Tabler](https://tabler.io/icons) line SVGs, inlined as partials in `app/views/shared/icons/` and rendered via `topic_icon_svg(token)` (mapped per-slug in `PATH_ICON_TOKENS`) so they inherit `currentColor`. Keep all icons monochrome line-style from one of these two sources — never mix in random third-party/PNG icons. Size them via the parent container's CSS (`svg { height: 1rem; width: 1rem }` inside `.btn`/`.path-card__icon`/etc), not inline `class:`.
- **Hover/focus:** Centralized in `base.css` via `:is(a, button, input, textarea)` — components don't need per-element transition/box-shadow rules.
- **Meta tags:** `<meta name="color-scheme" content="light dark">` plus a light/dark `theme-color` pair in the layout's `<head>` so native browser chrome (scrollbars, form controls) follows the theme.
- **Flash:** `<%= render "shared/flash" %>` renders a Turbo Frame fixed-position pill at the top; `element-removal` Stimulus controller auto-dismisses after 4s. Styled by `flash.css`.

## Docs

- `docs/VISION.md` — what we're building, for whom, why
- `docs/MVP.md` — phased rollout: v0.1 (static catalog) → v0.2 (auth + progress) → v0.3 (community content)
