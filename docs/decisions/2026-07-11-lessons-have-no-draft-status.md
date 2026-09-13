---
summary: A lesson added to a published course goes live immediately; transparency (AdminAction log) instead of a per-lesson draft gate.
date: 2026-07-11
status: accepted
---

# Lessons have no draft status

Lesson position is global within the profession (prev/next, «Продолжить», progress
bars, counter caches), so filtering drafts would leak into every hot query for a rare
scenario. A scoped editor is trusted by definition of the ladder. The safeguard is
transparency: creating or deleting a lesson in a published course is logged to
`AdminAction` (the «Живой контент» tab in `/admin/log`).

Related: [content model](../conventions/content-model.md).
