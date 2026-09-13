---
summary: ERB, Turbo, i18n, emblems, flash and the shared account menu.
paths:
  - "app/views/**"
  - "app/helpers/**"
  - "config/locales/**"
---

# View conventions

## HTML-first

- ERB only — no Haml, Slim, ViewComponent. Partials for reuse.
- Server-render everything; Turbo Frames for partial updates, Turbo Streams for pushes.
- `loading: :lazy` frames for server-expensive fragments.
- Flash: `render "shared/flash"` — a fixed Turbo Frame pill auto-dismissed by the
  `element-removal` controller; streams replace `:flash`.

## i18n

All user-facing strings via `I18n.t`; Russian first, keys in English. Add every key
to both `ru.yml` and `en.yml` — `test/locales_parity_test.rb` fails otherwise.

## Icons and emblems

- `icon_tag "name"` — see [css.md](css.md#icons).
- Profession/chapter emblems are data: `paths.icon` / `courses.icon`, picked in
  `admin/shared/_icon_field` (radios, no JS). `icon` is the stored choice and may be
  blank; `emblem` is what to render (`Course#emblem` → its path's, `Path#emblem` →
  `Icon::DEFAULT_EMBLEM`). Keep them two methods — overriding the reader breaks
  `allow_blank` and form checkedness. `Icon.emblems` globs the `-light` files.

## Account menu — one list, two containers

Wide screens: a native `popover` hub; compact: a `<details>` sheet. Both render the
same `shared/_account_identity` + `shared/_account_links` — never inline those rows
into one surface (they drifted once). Nav words sit in the bar on desktop and inside
the sheet on mobile; the guest block is sheet-only. Scope sheet-only CSS to a
specific class, not `.header__menu-panel .badge`.
`test/system/account_menu_test.rb` asserts both surfaces offer the same items.
