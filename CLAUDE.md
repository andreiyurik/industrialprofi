# IndustrialProfi

**The Odin Project + roadmap.sh — for industrial professions.**

Free platform with structured career roadmaps: stages → skills → official standards → practical tasks → progress tracking. Like The Odin Project teaches web development through reading documentation and building projects, IndustrialProfi teaches industrial trades through reading official standards (ГОСТ, ASME, НАКС) and doing real-world practice.

Content structure follows The Odin Project (profession → course → lesson, binary completion). UI follows canonical DHH style — same patterns as Basecamp's open-source Rails apps (Writebook, Fizzy, Upright, Once-Campfire). Target market: CIS (Russia, Kazakhstan).

## Stack

- Ruby 4.0.5 / Rails 8.1.3
- SQLite3 (+ Solid Queue, Solid Cache, Solid Cable)
- Hotwire: Turbo + Stimulus
- Tailwind CSS 4 via `tailwindcss-rails` gem
- Propshaft + Importmap (no Node.js, no bundler)
- Kamal 2 + Docker + Thruster
- Auth: `has_secure_password` (bcrypt)
- Tests: Minitest + fixtures + Capybara

## Commands

```
bin/dev                    # dev server (Rails + Tailwind watcher)
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
app/assets/tailwind/       # Tailwind CSS entry (application.css)
app/assets/builds/         # compiled CSS output (git-ignored)
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

**Tailwind utilities in ERB.** No custom CSS unless unavoidable. The entry point is `app/assets/tailwind/application.css` with `@import "tailwindcss"`. No `tailwind.config.js` — Tailwind v4 uses CSS-first configuration.

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
- No `tailwind.config.js` or `postcss.config.js`. Tailwind v4 is CSS-first.
- No API-first design. HTML-first, API only when a real consumer exists.
- No `before_action` chains longer than 2. Keep auth simple.
- No concerns until a model exceeds ~200 lines. Premature extraction is worse than duplication.

## UI — Canonical DHH Style (Basecamp Rails apps)

Reference implementations: `basecamp/writebook` (most relevant — content-focused), `basecamp/fizzy`, `basecamp/upright`, `basecamp/once-campfire`. None of them use Tailwind — they ship custom CSS with OKLCH primitives. We bridge that to our stack: **Tailwind 4 utilities in ERB, but with OKLCH semantic tokens defined via `@theme`** so colors auto-swap with `prefers-color-scheme`.

- **Fonts:** System stack only (`system-ui`, `-apple-system`, `BlinkMacSystemFont`, "Segoe UI", "Noto Sans"). No Google Fonts, no web fonts, no Inter. Faster, no FOUT, looks native.
- **Color tokens (use these, not raw hex/Tailwind colors):**
  - `bg-canvas` / `text-ink` — page background and primary text (swap in dark mode)
  - `text-link` — links (blue, hue-shifted in dark)
  - `text-positive` / `text-negative` — success/error
  - `text-marker` — orange accent for highlights, important callouts
  - `bg-subtle` / `bg-subtle-light` / `text-ink-subtle` — quiet UI: borders, dividers, secondary text
- **OKLCH primitives:** Defined in `:root`, swapped at `@media (prefers-color-scheme: dark)`. Semantic tokens reference primitives via `oklch(var(--lch-*))` — change a primitive, every semantic token using it updates. See `app/assets/tailwind/application.css` head.
- **Light-first.** Default theme is light. Dark mode kicks in automatically via system preference. No `.dark` class on `<html>`, no `dark:` modifiers — color swap happens at the OKLCH primitive level.
- **Page container:** `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
- **Reading column:** `max-w-prose mx-auto` (lessons), `max-w-4xl mx-auto` (course pages)
- **Cards:** `bg-canvas ring-1 ring-subtle rounded-md p-6` (rings instead of shadows — works in both themes)
- **Buttons:** Tailwind utilities inline. Primary = `bg-ink text-canvas`. Secondary = `ring-1 ring-subtle text-ink`. No `.btn` abstraction until 3+ button shapes appear in the same view.
- **Icons:** Heroicons (already in the stack) via inline SVG. Apply color via `text-*` on the `<svg>` and `fill="currentColor"` inside.
- **Layout regions:** Semantic HTML5 (`<header>`, `<main>`, `<aside>`, `<footer>`) — see Writebook `app/views/layouts/application.html.erb` for reference structure with `yield :header`, `yield :sidebar` blocks.
- **Flash:** `<%= render "shared/flash" %>` renders a Turbo Frame at the top of the layout; `element-removal` Stimulus controller auto-dismisses after 4s.
- **No CSS utility soup.** Extract a Tailwind `@utility` only when the same set of 6+ classes is repeated in 3+ places. Otherwise inline. (Current `application.css` has legacy `@utility`s — migrate to tokens or inline as views are touched.)

## Docs

- `docs/VISION.md` — what we're building, for whom, why
- `docs/MVP.md` — phased rollout: v0.1 (static catalog) → v0.2 (auth + progress) → v0.3 (community content)
