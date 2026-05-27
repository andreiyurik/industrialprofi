# IndustrialProfi

Wiki-style platform for trade professions (welders, electricians, industrial workers). Structured career roadmaps with official documents, practical tasks, and progress tracking. Target market: CIS (Russia, Kazakhstan).

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

## Anti-patterns

- No React, Vue, or SPA. This is a Hotwire app.
- No Devise. Use `has_secure_password` + a hand-rolled `SessionsController`.
- No `respond_to` JSON/HTML unless explicitly needed.
- No `tailwind.config.js` or `postcss.config.js`. Tailwind v4 is CSS-first.
- No API-first design. HTML-first, API only when a real consumer exists.
- No `before_action` chains longer than 2. Keep auth simple.
- No concerns until a model exceeds ~200 lines. Premature extraction is worse than duplication.

## UI Conventions

- Page content: `max-w-4xl mx-auto px-4`
- Section spacing: `space-y-6` or `mb-6`
- Cards: `rounded-xl border bg-card p-4`
- Buttons/inputs: `rounded-lg`
- Dark mode: use `dark:` variants for all custom colors
- Responsive: mobile-first, `sm:`/`md:`/`lg:` breakpoints

## Docs

- `docs/VISION.md` — what we're building, for whom, why
- `docs/MVP.md` — phased rollout: v0.1 (static catalog) → v0.2 (auth + progress) → v0.3 (community content)
