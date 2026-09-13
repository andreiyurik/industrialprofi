---
summary: Stimulus controller shape, JS helper modules and native Web APIs instead of dependencies.
paths:
  - "app/javascript/**"
  - "config/importmap.rb"
---

# JavaScript conventions

Importmap, no Node, no npm, no build. Stimulus only for behaviour the server can't
provide. References: `tmp/references/fizzy/app/javascript/` for controller shape,
`tmp/references/once-campfire/app/javascript/` for native Web APIs.

## Stimulus controllers (Fizzy idiom)

- True ES private fields and methods (`#timer`, `#save()`, `get #dirty()`); the
  public surface is lifecycle + actions only.
- Section dividers inside a controller: `// Lifecycle`, `// Actions`, `// Private`.
- Module-scope constants in `UPPER_SNAKE` (`const AUTOSAVE_INTERVAL = 3000`).
- `static values = { debounceTimeout: { type: Number, default: 300 } }` — object form
  with defaults.
- Bind debounced/throttled handlers once in `initialize()`/`connect()`, not per event.
- Submit with `this.element.requestSubmit()`.

## Helpers

`app/javascript/helpers/*.js` (pinned `under: "helpers"`) are small pure-function
modules — `timing_helpers` (`debounce`/`throttle`/`rafThrottle`/`nextFrame`),
`dom_helpers`, `http_helpers`. Import named functions. Add an export only when a
real caller exists.

## Prefer the platform

`<details>`, `popover`, `<dialog>`, Web Share, clipboard, `Intl` for dates, paired
`view-transition-name`s — before any library. Use native `fetch`; don't pin
`@rails/request.js` or other Fizzy npm deps.
