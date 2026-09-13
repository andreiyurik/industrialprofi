---
summary: The lesson format — WHY, ranked further-study links, close by usefulness; practice-task brief.
paths:
  - "db/seeds/curriculum/**"
---

# Lesson format

The full Russian authoring canon is `tools/AUTHOR_PROFESSION.md`; this page is the
short contract every lesson follows.

1. **WHY** — the `description` field, also `<meta name="description">`. One
   self-contained sentence ≤155 chars that honestly answers "why spend time on this"
   and opens with the topic in natural search phrasing. No keyword stuffing.
2. **Further-study links** — curated and ranked into required vs recommended (plain
   captions, no star glyphs), type-appropriate:
   - official `document`s for regulated topics (ГОСТ, ПУЭ, НАКС, IEC, ISO, RFCs,
     language specs);
   - otherwise the most useful quality source: `video`, `article`, `tool`;
   - where no standard exists, best practice honestly labelled as such.
   - Each link may carry a one-line `note` (chapter, sections, minutes).
3. **Close by usefulness, not a template** — a theory lesson ends with thoughtful
   self-check questions in a `> [!ПРОВЕРЬ]` callout; a practical task, diagram or
   infographic only where it genuinely adds value.

## Practice lessons (`kind: practice`)

`difficulty:` — beginner (paper/bench, safe, ~free), intermediate (real tools),
advanced (capstone) — drives the `/projects` grid. «## Задание» brief:
**Цель** → **Понадобится** (honest materials + prices/free alternatives) →
`> [!ОПАСНО]` where anything is live → **Шаги** → **Что сдать** (→ journal entry) →
**Самопроверка** (yes/no against the standard). Reference lessons (slugs, listed
in `PagesController::REFERENCE_LESSON_SLUGS`): `chtenie-shem-i-ugo`,
`soedinenie-provodov`, `sborka-shchita`.

## Tools and callouts

- Name the de-facto-standard tool for a recurring task (Modbus Poll, UaExpert,
  Wireshark, the canonical PLC IDE): a `tool` resource plus a `> [!СОВЕТ]` mention.
- Callouts are a blockquote whose first line is a marker (`[!ВАЖНО]`, `[!ПРОВЕРЬ]`…);
  `ApplicationHelper#enrich_prose` upgrades them on render.

## Verify

`bin/rails content:audit` and `bin/rails content:links` for the mechanical checks;
`tools/QA_REVIEW.md` for the judging half.
