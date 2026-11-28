---
summary: Animated lesson schemes are curated inline SVG + CSS in the repo, placed as `diagram:<slug>`; SVG uploads stay forbidden.
date: 2026-11-28
status: accepted
revisit_when: a practitioner needs to add or fix a scheme without a pull request
---

# Lesson diagrams are code

Where a topic is about something that flows, switches or changes in time, the lesson gets
an animated scheme: an ERB partial and a stylesheet in the repo, registered in `Diagram`
and placed with `![alt](diagram:<slug>)`. No JavaScript, no upload, no new model.

**Why.** Inline SVG follows both themes and the translations, which an `<img>` SVG would
not, and review by pull request keeps the XSS ban of
[editor-gated images](2026-06-27-lesson-images-editor-gated.md). Photos and software
screenshots still come through the illustration queue.

Related: [authoring prompt](../../tools/LESSON_DIAGRAM.md).
