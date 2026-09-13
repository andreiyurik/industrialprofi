---
summary: A wanted profession lives in locale copy (paths.soon_wanted), never as an empty Path row; Path has no coming_soon status.
date: 2026-07-16
status: accepted
---

# An unwritten profession is copy, never an empty Path

The vacancy board lives in `ru.yml → paths.soon_wanted`, mirrored by
`contribute.wanted` and [PROFESSION_BACKLOG](../PROFESSION_BACKLOG.md).

Empty `Path` rows were wrong twice over: 13 contentless rows polluted every admin
list and picker, and the board rendered "whatever stubs exist" instead of what we want
to say — which is how it silently became all-АСУ-ТП. So `Path::STATUSES` is only
`draft | pending_review | published` (a `Course` may still be `coming_soon`).
Reordering the board is a locale edit, not a migration.

Related: [narrow wedge, wide ceiling](2026-06-12-narrow-wedge-wide-ceiling.md).
