---
summary: Controller, model, job and test shape — Rails defaults, Fizzy for the bigger patterns.
paths:
  - "app/models/**/*.rb"
  - "app/controllers/**/*.rb"
  - "app/jobs/**/*.rb"
  - "app/mailers/**/*.rb"
  - "lib/**/*.rb"
  - "test/**/*.rb"
---

# Rails conventions

When in doubt, do what Rails does by default, then check how Fizzy does it:
`tmp/references/fizzy/` (read its `STYLE.md` once). Take the idiom, not its
multi-tenancy, MySQL sharding, Web Push or realtime broadcasts.

## Controllers

- RESTful: the 7 actions first; a new resource (`resource :completion`) before a
  custom action.
- Shape: `before_action :set_x` scoped with `only:`/`with_options`; a `private`
  section of `set_*` / `ensure_*` helpers; `params.expect(...)`.
- No `before_action` chain longer than 2. No service objects for CRUD.
- A turbo replacement rendered from several actions gets one private render helper
  (Fizzy's `render_card_replacement`).
- No `respond_to` JSON/HTML unless a real consumer exists.
- Public controllers opt out with `allow_unauthenticated_access` (still restores
  `Current.user`); everything else requires authentication by default.

## Models

- Fat models, intention-revealing APIs the controller calls directly.
- Member order: includes → associations → callbacks → scopes → public methods → private.
- Extract a concern (`extend ActiveSupport::Concern`, `included do … end`) only past
  ~200 lines — premature extraction is worse than duplication.
- Heavy use of scopes, including `case`-dispatch scopes.

## Jobs

Solid Queue. Async work goes in a job that calls a model method (`_later` / `_now`
pairs per Fizzy's STYLE.md).

## Tests

- Minitest + fixtures + Capybara. No RSpec, no FactoryBot.
- Test critical paths; never test Rails itself.
- Re-run tests when Ruby, ERB or `.yml` changed. `bin/rails test path/to/file_test.rb`
  for the file you touched, the full suite before hand-off.
