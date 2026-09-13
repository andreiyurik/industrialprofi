---
summary: Every URL carries /ru or /en; content lives in exactly one locale; hreflang only on chrome pages; UI locales kept at key parity.
date: 2026-08-04
status: accepted — settled, don't revisit
---

# Symmetric URL locales

- One gTLD domain; every user-facing URL carries the prefix. `/` and unprefixed URLs
  301 into the default locale (`ApplicationController#redirect_unlocalized`).
- The route segment is optional — `scope "(:locale)"`, the Rails Guides pattern; a
  mandatory segment breaks positional URL-helper args — but canonical in practice.
- Content lives in exactly one locale (`Path#locale`): the wrong prefix 301s home from
  paths/courses/lessons#show, so no thin `/en` mirrors exist.
- hreflang pairs only on chrome pages (`SeoHelper#bilingual_page?`); emails render in
  `users.locale`.
- The interface is translated; `test/locales_parity_test.rb` keeps `en.yml` and
  `ru.yml` key-for-key. An EN content catalog stays gated on a native expert
  ([VISION → language expansion](../VISION.md#language-expansion--the-recorded-plan-founder-decision-july-2026)).
