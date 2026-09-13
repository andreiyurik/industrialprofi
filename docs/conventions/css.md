---
summary: Stylesheet layout, OKLCH colour tokens, fonts, naming, spacing and icons — the Writebook canon.
paths:
  - "app/assets/stylesheets/**"
  - "app/assets/images/icons/**"
  - "app/assets/fonts/**"
---

# CSS conventions

Plain CSS, Writebook's file layout 1-to-1 (`_reset.css`, `base.css`, `colors.css`,
`layout.css`, `utilities.css`, `buttons.css`, `inputs.css`, `panels.css`…) plus
domain files. Reference: `tmp/references/writebook/app/assets/stylesheets/`.

## Build and cascade

- `application.scss` is an alphabetical list of `@use` lines; dartsass only
  concatenates and minifies it into `app/assets/builds/application.css`.
- **A new stylesheet must be added to that list** — otherwise it silently never
  ships; `test/assets/stylesheet_manifest_test.rb` catches it.
- No CSS layers: load order (filename-alphabetical, bedrock prefixed `_`) is the
  cascade. Gem stylesheets (lexxy, trix) stay separate links.
- Never write Sass (`$vars`, mixins, `@extend`), `@apply`, `@theme`, `@layer`, or
  `@import` between files. No `dark:`/`sm:` prefixes — use `@media` in the file.

## Colour

- OKLCH primitives in `:root` of `colors.css` (`--lch-*`); semantic tokens reference
  them via `oklch(var(--lch-*))` (`--color-bg`, `--color-ink`, `--color-link`,
  `--color-positive`/`-negative`…). **No raw hex/rgb/hsl anywhere.**
- A new colour is added as a primitive first. Historical names hold dark values
  (`--lch-black` = near-white ink, `--lch-white` = near-black bg — never literal 0%).
- Single dark theme, `color-scheme: dark`; no light mode, no theme switch.
- Monochrome + blue `--color-link` is the default. Colour is allowed where it helps
  scan or signal state (resource-type badges: norm=red, book=teal, video=purple,
  article=yellow, tool=green in `badges.css`) — reuse `.badge--*`, never a one-off hue.

## Type

- Self-hosted only (`app/assets/fonts/`, `@font-face` in `_fonts.css`); no CDN.
- `--font-sans` (Inter) for body/UI, `--font-display` (Inter Tight) for headings,
  declared in `base.css`. Largest titles: `font-weight: 800` + uppercase.
- Two scoped exceptions, not precedents: GOST type B for normative table/diagram
  labels; IBM Plex Mono for the lesson table-of-contents rail.

## Naming and components

- Hyphenated-flat (`.btn`, `.panel`), `--modifier` variants, `__element` only for a
  nested DOM piece.
- Component-local variables with defaults (`--btn-background`), overridden by modifiers.
- `.panel` (card), `.btn` (outlined; `--reversed` filled primary, `--negative`/
  `--positive`, `--small`/`--large`), `.input` (`--mono`/`--textarea`), `.badge`.
  Hover/focus is centralized in `base.css`.
- Containers: `.container` (72rem), `.container--reading` (56rem); `.section` /
  `.section--divided`. Body is a 3-row grid so the footer sticks.

## Spacing

Use `--inline-space` / `--block-space` (+ `-half` / `-double`) from `utilities.css`,
not raw rem/px. Three sizes only — near-miss literals (container gutters, the
`0.75rem` cluster) stay literal on purpose; don't add a fourth tier for a repeat.

## Motion (Fizzy idiom)

- Named keyframes live in `animation.css`. Top-layer enter/exit uses
  `@starting-style` + `transition-behavior: allow-discrete`.
- Explicit `transition-property` lists (never `all`), `ease-out`, ~100–300ms.
- Busy state: `form[aria-busy]` hides button children and overlays a masked
  `::after` spinner (`buttons.css`).
- Don't borrow once-campfire's CSS: its light+dark `filter: invert()` fights OKLCH.

## Icons

- One family: Phosphor, self-hosted in `app/assets/images/icons/`, one line each in
  `icons.css`, rendered by `icon_tag "name"` as a `mask-image` painted with
  `currentColor` (no SVG in HTML).
- Size from `--icon-size` on the context (default `1em`).
- Weight is in the name: `-light` for emblems ≥32px, regular below, `-fill` only
  as state (done/active/saved). Never bold, thin or duotone; never another set or PNG.
- `test/helpers/icon_tag_test.rb` fails on a typo, orphan or missing file.

## Verify

CSS can't break server rendering — check it visually in the browser, not with tests.
