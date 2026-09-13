---
summary: How the wiki is written and kept true — page types, frontmatter, links, the record/lint operations, Mermaid, Excalidraw, Obsidian.
paths:
  - "docs/**/*.md"
  - "AGENTS.md"
  - "CLAUDE.md"
---

# Docs conventions

`docs/` is a small wiki in the spirit of Karpathy's
[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), adapted
to a codebase: **the code is the source of truth**, the wiki is the compiled
understanding of it, `AGENTS.md` is the schema (`CLAUDE.md` imports it), and [README.md](../README.md) is the
index. Humans own the wiki; agents help keep it true.

## Page types

| Folder | Holds | Changes when |
|---|---|---|
| `docs/*.md` | product and operations (VISION, DEPLOY…) | strategy or runbook changes |
| `architecture/` | one page per subsystem: what it does, its constraints, a diagram | a subsystem ships or changes shape |
| `conventions/` | how to write code in one area; also Claude Code rules | the team agrees a new convention |
| `decisions/` | one settled decision: what, why, when to revisit | a decision is made or superseded |
| `diagrams/` | Excalidraw drawings and their SVG exports (created with the first one) | a human redraws them |

English, concise, one home per fact — link instead of repeating. No changelog prose:
git history covers "when". The Russian content-authoring docs live in `tools/`.

## Frontmatter

```yaml
---
summary: One line — the same line the index shows.     # required on every page
paths:                                                 # code this page describes or governs
  - "app/models/lesson.rb"
date: 2026-07-15                                       # decisions only
status: accepted                                       # decisions: accepted | superseded by <link>
revisit_when: the trigger that reopens it              # decisions, optional
---
```

On a convention page `paths` is also what Claude Code matches to load the rule.

## Links

Standard relative Markdown links — `[editing pipeline](../architecture/editing-pipeline.md)`
— never `[[wikilinks]]`: they work in Obsidian (graph, backlinks, rename-safe), on GitHub
and for agents alike. Link code by path in backticks.

## Operations

- **Record** — when work settles a question worth keeping, file it back: a new decision
  page, a changed architecture page, a line in the index. Answers that live only in chat
  are lost.
- **Lint** — `bin/rails test test/docs` checks mechanically (summary, index, `paths` globs,
  links, rule symlinks). Periodically ask Claude for the judging half: claims the code
  has overtaken, contradictions between pages, subsystems with no page, orphans.
- A new page is not done until it is in [README.md](../README.md).

## Diagrams

- **Mermaid** for logic — flows, sequences, state, data model. It is text: GitHub and
  Obsidian render it, agents read and update it for a few tokens. Default choice.
- **Excalidraw** for a few hand-drawn overview pictures humans own. Draw in Obsidian with
  the Excalidraw plugin into `docs/diagrams/<name>.excalidraw.md`, enable its auto-export
  to SVG, and embed the SVG in the page it illustrates with a normal image link. Put the
  essential meaning in the page text too — agents don't read drawings (`Read` of
  `*.excalidraw.md` is denied in `.claude/settings.json`: it is kilobytes of JSON).

## Obsidian

Open the repository root as a vault. In Settings → Files and links, turn off «Use
[[Wikilinks]]» and set new links to relative paths; add `app/`, `db/`, `test/`, `tmp/`,
`vendor/` to Excluded files. `.obsidian/` is gitignored — vault settings are personal. Install the Excalidraw community plugin
yourself if you draw.
