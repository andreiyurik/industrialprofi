---
description: Removes comments that restate code from a file or folder, keeping one-line non-obvious whys. Use for the module-by-module cleanup toward Basecamp comment density.
argument-hint: "<file or folder, e.g. app/models/user.rb>"
disable-model-invocation: true
---

Prune comments in: $ARGUMENTS. Only comments change — no code, names or formatting.

For every comment decide:

- **Delete** when it restates the code or a name, narrates history ("used to", "was
  moved"), cites a doc section, explains Rails itself, or duplicates a `docs/` page.
- **Shorten to one line** when a genuine *why* is buried in prose — keep the constraint,
  drop the story.
- **Keep** when removing it would let a reasonable engineer "fix" something on purpose:
  invariants, security/data-loss guards, surprising workarounds, magic comments and
  directives (`frozen_string_literal`, `rubocop:`, `<%# locals: %>`, Stimulus section
  dividers).
- **Move** rationale that is valuable but long into the matching `docs/architecture/` or
  `docs/decisions/` page — only if that page doesn't already say it.

Then:

1. Show before/after comment-line counts for the scope
   (`grep -cE '^\s*(#|//)'` per file).
2. Run `bin/rubocop` on the files and the tests that cover them.
3. Summarize what was kept and why, in a few lines. Leave the diff for human review.
