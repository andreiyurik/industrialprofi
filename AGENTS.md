# IndustrialProfi

The Odin Project + roadmap.sh for industrial professions: profession → course → lesson →
official standards (ГОСТ, ПУЭ, НАКС) → practical tasks → binary progress. Russian-first,
CIS market. A conventional Rails 8 monolith in the Basecamp style.

## Git

IMPORTANT: never run write-side git (`add`, `commit`, `push`, `merge`, `tag`, `rebase`,
`reset`, `stash`, `checkout -b`) unless the user asks for that specific action in this
conversation — even if a plan or skill says to commit. Finish the file work, leave the tree
dirty, summarize, and report every git command you ran.

## Commands

```
bin/rails test test/models/lesson_test.rb    # run the tests for what you touched
bin/rails test                               # full suite before hand-off (test:system for Capybara)
bin/rails content:check                      # mechanical content QA
bin/references                               # clone Writebook, Fizzy, Campfire into tmp/references
```

CSS changes can't break tests — check them in the browser.

## North star

When convenience conflicts with these, they win:

- Minimum running cost under growth: one small VPS, SQLite on one disk. A feature must not
  add per-user disk, a paid dependency, S3, Node, a build step or ops surface.
- Self-developing content: suggest-edit → expert review → immutable revision, and the
  `member → editor → administrator` ladder. Credit contributors; never rank them.
- Only as many mechanics as needed. Before proposing a new one, check the decisions list in
  `docs/README.md` — many were declined with a trigger for revisiting.

## Code style

- HTML-first: ERB partials (no ViewComponent, Haml, Slim), Turbo Frames/Streams, Stimulus
  only where JS is required. Importmap — no Node or npm.
- RESTful: add a resource before a custom action. Fat models; no service objects for CRUD;
  extract a concern only past ~200 lines; at most 2 `before_action`s.
- No new gem unless Rails can't do the job. No Devise — auth is `has_secure_password` +
  `Current`/`Session`. No `respond_to` JSON without a real consumer.
- Every user-facing string goes through `I18n.t`. `config/locales/ru.yml` and `en.yml` are
  ~70k and ~50k tokens: find keys with grep and read only that range, never the whole file.
- Minitest + fixtures (no RSpec, no FactoryBot). Test critical paths, not Rails.
- Plain CSS: no Tailwind, Sass features, `@layer` or `@import`; colours only from the OKLCH
  tokens in `colors.css`; one dark theme.

## Comments

Default to no comment. Write one only for a non-obvious why the code can't express — one
line, rarely two. Never restate the code, narrate the change or cite a doc section; that
belongs in the commit message or `docs/`. Basecamp's apps run at 1–2% comment lines; match
them, not the older verbose files here.

```ruby
# Avoid
# The focus path IS one of the started paths — reuse that object, or its
# eager-loaded lessons and courses go to waste and the view re-queries them.
@focus_path = @started_paths.detect { |path| path == focus } || focus

# Preferred
# Reuse the started path so its eager loads aren't wasted.
@focus_path = @started_paths.detect { |path| path == focus } || focus
```

## References

`tmp/references/` (run `bin/references` if missing) holds the canon, each for one layer:
`writebook` — CSS layout, tokens, auth; `fizzy` — Rails/Hotwire shape and its `STYLE.md`;
`once-campfire` — native Web APIs instead of dependencies (not its light/dark CSS).
The Odin Project is the reference for product mechanics only.

## Docs

- `docs/README.md` — the wiki index: architecture, conventions, decisions, operations.
- `docs/conventions/<area>.md` — the detailed rules for rails, views, css, javascript,
  content model, lessons and docs. Read the matching page before editing that area.
- `tools/CONTENT_FACTORY.md` — the Russian content-authoring canon.
- When a user-visible feature ships, update `/roadmap` (`ru.yml → roadmap:`) and the
  matching `docs/architecture/` page. When a product call is settled, add a
  `docs/decisions/` page.
