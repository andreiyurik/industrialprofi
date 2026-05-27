# IndustrialProfi

**The Odin Project + roadmap.sh — for industrial professions.**

Free platform with structured career roadmaps: stages → skills → official standards → practical tasks → progress tracking. Like The Odin Project teaches web development through reading documentation and building projects, IndustrialProfi teaches industrial trades through reading official standards (ГОСТ, ASME, НАКС) and doing real-world practice.

Design, UX, and content structure follow The Odin Project as the primary reference. Target market: CIS (Russia, Kazakhstan).

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

## UI — The Odin Project Style

Design system follows The Odin Project (github.com/TheOdinProject/theodinproject):

- **Font:** Inter (Google Fonts, Cyrillic subset)
- **Colors:** teal-700 for primary actions, custom gold (#CE973E) for accents/highlights, gray for everything else
- **Dark mode:** `.dark` class on `<html>`, `@custom-variant dark (&:is(.dark, .dark *))`. Every element has explicit `dark:` pair.
- **Cards:** `bg-white shadow-sm rounded-lg` / `dark:bg-gray-800 dark:ring-1 dark:ring-white/10 dark:ring-inset`
- **Buttons:** `rounded-md`, primary=`bg-teal-700`, secondary=`border border-gray-300`
- **Badges:** `ring-1 ring-inset rounded-md` with color variants
- **Page container:** `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
- **Content width:** `max-w-4xl mx-auto` for reading pages
- **Card padding:** `p-8`
- **Section padding:** `py-16`
- **No shadows in dark mode** — use `ring-1 ring-white/10` instead

## Docs

- `docs/VISION.md` — what we're building, for whom, why
- `docs/MVP.md` — phased rollout: v0.1 (static catalog) → v0.2 (auth + progress) → v0.3 (community content)
