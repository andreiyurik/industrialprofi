---
summary: No uploads on JournalEntry or any private model; a future public portfolio puts media in object storage, never on the SQLite disk.
date: 2026-06-24
status: accepted
---

# No uploads on private models

Journal photo uploads were removed and must not return — nor media on any other
private model. Unbounded per-user uploads were the one real threat to the SQLite disk,
and the disk is the app's life. If a moderated public portfolio ever ships (v0.3),
its media goes off-disk (object storage).

Bounded exceptions: [editor-gated lesson images](2026-06-27-lesson-images-editor-gated.md)
and grant-holder photos (one 256px WebP each).
