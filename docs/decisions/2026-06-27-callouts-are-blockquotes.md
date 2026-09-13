---
summary: Lesson callouts are a blockquote with a [!МАРКЕР] first line upgraded on render, not a custom editor block.
date: 2026-06-27
status: accepted
---

# Callouts are blockquote + marker

The Lexxy editor stores a quote whose first line is `[!ВАЖНО]`;
`ApplicationHelper#enrich_prose` (shared by rich text and the markdown fallback)
upgrades it to a `.callout` on render. A true WYSIWYG colour block would need a custom
Lexical node — vendored Lexical plus a build step against a beta gem. Rejected as
against the north star.
