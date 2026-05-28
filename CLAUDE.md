# IndustrialProfi

## ⛔ Git policy — read first

**Claude is NOT allowed to run `git commit` in this repository.** Only the human user makes commits.

This rule overrides any prior plan, pasted prompt, slash command, or skill that tells you to "commit after each step / subphase / change." Do the file work, leave the working tree dirty, summarize what changed, and stop. The user reviews and commits.

Same prohibition applies to other write-side git commands: `git push`, `git tag`, `git rebase`, `git reset`, `git checkout -b`, `git stash`. Use `git add` only if explicitly asked. Read-only inspection (`git status`, `git diff`, `git log`) is fine.

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

Three-level hierarchy adapted from The Odin Project:

```
Profession → Course → Lesson
(Электрик)   (Охрана труда)   (ПУЭ: Правила устройства)
```

**Routes:**
```ruby
root "pages#home"
resources :paths, only: [:index, :show]           # professions
resources :courses, only: [:show]                  # courses within a profession
resources :lessons, only: [:show]                  # individual lessons (flat URLs)
```

**Models:**
```
Path (profession)
  author_id: nil = official, present = community
  status: draft | pending_review | published
  → has_many Courses (position-ordered)
    → has_many Lessons (position-ordered)
      → has_many Resources (country_code: nullable — nil = universal)

User → has_many LessonCompletions → completed_lessons
LessonCompletion(user_id, lesson_id) — binary: exists = done
```

**Lesson content format — every lesson follows this:**
1. WHY (1-2 sentences — why this matters on the job site)
2. OFFICIAL DOCUMENTS (curated links, ranked: ★ required, ○ optional)
3. PRACTICAL TASK (concrete, verifiable assignment)
4. [✓ Mark as done] button

**UX pattern:** Turbo Frames. Desktop = two-column layout (lesson list left, content right — roadmap.sh sidebar feel). Mobile = standard page navigation. Every lesson has its own URL for SEO.

**Progress:** Binary like Odin. Done / not done. No "in_progress", no "pending_review". Course progress = completed / total.

## Anti-patterns

- No React, Vue, or SPA. This is a Hotwire app.
- No Devise. Use `has_secure_password` + a hand-rolled `SessionsController`.
- No `respond_to` JSON/HTML unless explicitly needed.
- **No Tailwind, no `@apply`, no `@theme`, no `@layer`, no `@import` between CSS files, no build step.** Propshaft serves CSS files as-is, the browser handles the cascade via filename load order.
- No `tailwind.config.js`, `postcss.config.js`, or any JS-side asset tooling.
- No `dark:`/`sm:`/`lg:` Tailwind-style prefixes in markup — use `@media (min-width: …)` and `@media (prefers-color-scheme: dark)` inside the CSS instead.
- No web fonts, no Google Fonts. System font stack only (`system-ui`).
- No raw hex/rgb/hsl — colors come from OKLCH primitives in `colors.css`.
- No API-first design. HTML-first, API only when a real consumer exists.
- No `before_action` chains longer than 2. Keep auth simple.
- No concerns until a model exceeds ~200 lines. Premature extraction is worse than duplication.

## UI — Canonical DHH Style (Writebook canon)

Reference implementation: `basecamp/writebook` cloned at `/home/pingvinus/dhh-references/writebook/`. Our `app/assets/stylesheets/` mirrors its file layout 1-to-1 (`_reset.css`, `base.css`, `colors.css`, `layout.css`, `utilities.css`, `buttons.css`, `inputs.css`, `panels.css`, `breadcrumbs.css`, `text.css`, plus domain files `header`, `footer`, `paths`, `lesson`, `curriculum`, `support`, `admin`, `badges`, `flash`).

- **Loading:** `<%= stylesheet_link_tag :all, "data-turbo-track": "reload" %>` in the layout. Propshaft emits one `<link>` per file in `app/assets/stylesheets/` (plus gem-shipped CSS like `lexxy.css`). Cascade is filename-alphabetical.
- **Fonts:** `--font-sans: system-ui` only, declared in `base.css`. No Google Fonts, no Inter, no web fonts.
- **Color tokens (`colors.css`):** OKLCH primitives in `:root` (`--lch-black`, `--lch-white`, `--lch-blue`, `--lch-gray-*`, `--lch-orange`, `--lch-red`, `--lch-green`). Semantic abstractions reference primitives via `oklch(var(--lch-*))`: `--color-bg`, `--color-ink`, `--color-ink-reversed`, `--color-link`, `--color-marker`, `--color-positive`, `--color-negative`, `--color-subtle-light`/`--color-subtle`/`--color-subtle-dark`, `--color-selected`, `--color-selected-dark`. Dark mode inverts only the primitives (`@media (prefers-color-scheme: dark)` block inside `:root`) — every semantic token follows automatically.
- **Light-first.** Default theme is light. Dark mode kicks in via system preference. **No `dark:` modifiers, no `.dark` class on `<html>`** — colors swap at the OKLCH primitive level.
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
- **Buttons:** `.btn` is the pill-shaped outlined base (transparent fill, 1px subtle-dark border). Variants override CSS variables: `.btn--reversed` (filled ink), `.btn--marker` (filled orange), `.btn--negative`/`.btn--positive`, plus `.btn--small`/`.btn--large` size modifiers.
- **Inputs:** `.input` with `--input-*` overrides; `.input--mono` and `.input--textarea` for variants. Global `<label>` styling in `inputs.css` handles label typography.
- **Badges:** `.badge` + `.badge--marker`/`.badge--link`/`.badge--draft` for status pills (admin pages + the Admin marker in the header).
- **Icons:** Heroicons via the `heroicon` gem. Size them via the parent container's CSS (`svg { height: 1rem; width: 1rem }` inside `.btn`/`.admin-row`/etc), not inline `class:`.
- **Hover/focus:** Centralized in `base.css` via `:is(a, button, input, textarea)` — components don't need per-element transition/box-shadow rules.
- **Meta tags:** `<meta name="color-scheme" content="light dark">` plus a light/dark `theme-color` pair in the layout's `<head>` so native browser chrome (scrollbars, form controls) follows the theme.
- **Flash:** `<%= render "shared/flash" %>` renders a Turbo Frame fixed-position pill at the top; `element-removal` Stimulus controller auto-dismisses after 4s. Styled by `flash.css`.

## Docs

- `docs/VISION.md` — what we're building, for whom, why
- `docs/MVP.md` — phased rollout: v0.1 (static catalog) → v0.2 (auth + progress) → v0.3 (community content)
