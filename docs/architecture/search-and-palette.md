---
summary: SQLite FTS5 lesson search behind LessonSearch and the Ctrl+K command palette — zero new dependencies.
paths:
  - "app/models/lesson_search.rb"
  - "app/controllers/searches_controller.rb"
  - "app/javascript/controllers/palette_controller.js"
  - "app/views/shared/_palette.html.erb"
  - "lib/tasks/search.rake"
---

# Search and command palette

- **Search** (`/search`): SQLite FTS5 behind the `LessonSearch` PORO — all FTS SQL lives
  there. `Lesson` commit callbacks sync the index; run `bin/rails search:rebuild` after a
  restore. Published only; bm25 weights title > description > body; quoted-prefix terms
  (Russian morphology + injection safety); `<mark>` snippets.
- The live form debounces an auto-submit into a Turbo Frame; the input sits outside the
  frame so it keeps focus.
- **Palette** (`shared/_palette`, Fizzy's jump menu): the header search icon is a real
  link to `/search` (no-JS fallback); Ctrl/Cmd+K (k/л) or `/` opens a `<dialog>` with live
  results in a `palette_results` frame and quick-destination tiles while blank. One
  Stimulus controller; no arrow-key navigation on purpose.
