# Content factory — how quality materials are built

How IndustrialProfi produces deep, structured, trustworthy materials for many
professions — fast with AI, then verified by experts, then improved by readers —
without ever sacrificing trust, and without the founder being the bottleneck.

> **The one invariant:** AI accelerates, experts verify and publish, the
> immutable pipeline protects. AI never publishes. AI never overwrites what a
> human touched. All AI runs at authoring/maintenance time (Claude Code console
> or any external LLM) — **the running app stays LLM-free** (no paid runtime
> dependency, no per-user cost), exactly like the deliberate no-chatbot decision.

The real bottleneck of quality-at-scale is **expert-review capacity**, not
generation. AI makes drafts cheap; trust is scaled by people. So drafts may pile
up in `draft`, but publication is paced to what experts can verify. Publishing
unreviewed AI content would destroy the trust that is the whole moat.

## The pipeline (per profession)

1. **Skeleton + lessons (AI, offline).** Design the structure and write lessons
   with `tools/AUTHOR_PROFESSION.md` (Russian). It produces content in the seed
   format and stops to confirm the roadmap before writing. Content reaches the DB
   either as the seed `.md` tree (`bin/rails` seed) or as a single pasted YAML via
   `/admin/imports/new` (preview → confirm) — both land as **draft**, `origin:
   "ai"`, behind the same import safety.
2. **Depth, one lesson at a time (AI, offline).** Deepen a written lesson with
   `tools/DEEPEN_LESSON.md` (Russian) — focused per-lesson is where real depth
   comes from (a single one-shot for a whole profession is shallow). Re-import:
   the importer **refreshes pristine AI drafts in place** (see "update-if-pristine"
   below); human-edited lessons are frozen.
3. **Diagrams/infographics — only where they help** (`tools/LESSON_IMAGES.md`,
   Russian, infographics via Nano Banana; hand-built SVGs also live in
   `public/lesson-images/`). **Technical diagrams must be expert-verified** — a
   subtly wrong schematic is dangerous and trust-destroying.
4. **Expert review (the quality gate).** Editors review drafts in the admin
   editor, verify technical accuracy / task realism / safety, and publish. The
   first human edit takes ownership (`origin: "human"`), freezing the lesson from
   any future AI re-import. Every change appends an immutable `LessonRevision`.
5. **Reader suggestions (the community).** Readers propose edits → editor review
   → revision. Self-developing, Wikipedia-style, but moderated.
6. **AI QA at scale (ongoing).** Keep quality from rotting across many
   professions. Two halves — see "Quality assurance" below.

## update-if-pristine (the safety mechanism)

The database is the source of truth. The importer (`lib/curriculum_document.rb`,
mirroring `lib/curriculum_importer.rb`) is a **create-or-refresh feed** governed
by `Importable#frozen_for_import?`:

- **new** row → created (`origin: "ai"`, draft);
- **pristine** row (importer-owned, unchanged by a human) → **refreshed** — so AI
  can deepen its own stubs on re-import;
- **frozen** row (a human authored it, edited it, or it carries any revision) →
  **skipped** — human work is never overwritten.

Freezing is per-row, not per-subtree: a frozen (e.g. published) path is still
walked, so new lessons still import beneath it.

## Format philosophy — usefulness over completeness

**The criterion is usefulness and clarity, never box-ticking.** A lesson with
practice or a diagram added "to tick a box" is worse than one without.

- **Every lesson:** WHY (`description`, ≤155 chars, doubles as the SEO snippet) →
  clear original explanation (`body`) → useful further-study links.
- **Theory lessons** end with **quality self-check questions** — a `> [!ПРОВЕРЬ]`
  callout (the established convention), thoughtful and referencing the standard,
  not trivia. Plain text for now;
  interactive quizzes are a separate, deferred roadmap item.
- **Practice tasks** (`kind: practice`) only where a hands-on skill genuinely
  warrants it — in the brief format (Цель → Понадобится → `[!ОПАСНО]` →
  Шаги → Что сдать → Самопроверка). Not every lesson.
- **Diagrams/infographics** only where they add real clarity.
- **Further-study links are type-appropriate** (`resources`):
  - **`document`** — official standards / regulated topics / protocols /
    programming languages (ГОСТ, ПУЭ, НАКС, IEC, ISO, RFCs, language specs).
    Auto-split into Норматив vs Книга by title.
  - otherwise, where the topic isn't regulated/spec-driven, point to the **most
    interesting quality source**: a good **YouTube** explainer (`video`), a
    strong **habr.com**-style article (`article`), or the **standard tool**
    (`tool`). The goal is genuinely useful depth, not a normative reference for
    its own sake.

## Quality assurance

- **(a) Mechanical — `bin/rails content:audit` / `content:links`.** Deliberately
  narrow (it does NOT enforce completeness): flags written theory lessons missing
  self-check questions, and resource links that no longer resolve. Rules, not
  judgment.
- **(b) Judgment — Claude Code console review** (`tools/QA_REVIEW.md`). Reads the
  DB read-only and judges clarity, technical correctness, depth, self-check
  quality, and whether a diagram/practice would help or is gratuitous. Output is
  **suggestions for experts** (or a report) — **AI proposes, a human disposes;
  never a direct write to live content.**

## Prompts (the operational kit)

Reusable, principle-baked **Russian** prompts live in `tools/` — `AUTHOR_PROFESSION.md`,
`DEEPEN_LESSON.md`, `LESSON_IMAGES.md` (and the review playbook `QA_REVIEW.md`).
They are the "AI" of
the factory — there is no AI feature inside the app itself.
