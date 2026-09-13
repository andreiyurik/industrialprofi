---
summary: Reader suggestions → expert review → immutable LessonRevision, contributor attribution and the outcome loop.
paths:
  - "app/models/lesson_suggestion.rb"
  - "app/models/resource_suggestion.rb"
  - "app/models/lesson_revision.rb"
  - "app/models/revision_diff.rb"
  - "app/models/track_record.rb"
  - "app/models/concerns/revisable.rb"
  - "app/models/concerns/suggestion_moderation.rb"
  - "app/controllers/lesson_suggestions_controller.rb"
  - "app/controllers/resource_suggestions_controller.rb"
  - "app/controllers/revisions_controller.rb"
  - "app/controllers/admin/lesson_suggestions_controller.rb"
  - "app/controllers/admin/resource_suggestions_controller.rb"
  - "app/controllers/admin/revisions_controller.rb"
  - "app/jobs/suggestion_emails_job.rb"
---

# Editing pipeline

How content improves without the founder: any reader proposes, an expert decides,
every applied change is kept forever.

```mermaid
sequenceDiagram
  actor Reader
  actor Expert as Expert (editor)
  participant Lesson
  participant Revision as LessonRevision
  Reader->>Lesson: «Предложить правку» → LessonSuggestion (pending)
  Note over Reader,Lesson: rate-limited 5/hour + honeypot
  Expert->>Lesson: approve → revise!(section, html)
  Lesson->>Revision: append immutable revision (version n+1)
  Expert-->>Reader: or reject — a reason is required
  Note over Reader: notify-dot → dashboard «Мои правки»<br>email only if unread after 24h (SuggestionEmailsJob)
```

- **Suggestions** (`LessonSuggestion`, `ResourceSuggestion`) share
  `SuggestionModeration`: `pending | approved | rejected`. Rejection always carries a
  reviewer comment.
- **Revisions** are append-only (`LessonRevision#readonly?` once persisted). Rollback
  is a new revision, never a rewrite. Readers see history at `/lessons/:slug/revisions`
  with word-level diffs (`RevisionDiff`).
- **Attribution, not competition**: a muted «Статью улучшили» credit from revisions;
  the founder's direct edits store `editor_name: nil`. `TrackRecord` powers the
  profile's accepted edits. No leaderboard ([decision](../decisions/2026-06-24-no-leaderboard.md)).
- Approvals and rejections are also written to the [admin action log](admin-and-operations.md).
- An approval that raises the profession's maturity stage is recorded on the
  suggestion (`raised_path_stage`) so the author hears about it.
- A revised lesson is frozen for re-import (`Revisable#frozen_for_import?`) — see
  [content model](../conventions/content-model.md#seed-loader-and-packs).
