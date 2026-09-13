---
description: Records a settled product or architecture decision in docs/decisions/ and the docs index so it is not re-proposed. Use when the user makes or reverses a call.
argument-hint: "<the decision in a sentence>"
---

Record the decision: $ARGUMENTS

1. Search `docs/decisions/` for an existing page on the same subject. If one exists, update
   it (or mark it `status: superseded by <link>` and write the new one) instead of adding a
   duplicate.
2. Create `docs/decisions/<YYYY-MM-DD>-<kebab-slug>.md` with today's date:
   frontmatter `summary`, `date`, `status: accepted`, optional `revisit_when`; then a title,
   the decision in one paragraph, **Why** (the trade-off, briefly), related links.
   Ask the user for the why or the trigger if the conversation doesn't contain them — don't
   invent rationale.
3. Add one line to `docs/README.md → Decisions` in date order.
4. If a convention or architecture page states the opposite, fix it in the same change.
5. Run `bin/rails test test/docs`.
