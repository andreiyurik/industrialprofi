---
summary: Lesson image upload is editor-only (rich_body/rich_task), image-only, no SVG, 10 MB, WebP variants, no watermark, blobs on local disk.
date: 2026-06-27
status: accepted
---

# Lesson images: editor-gated upload

- Uploads are disabled on the member/suggestion path and on the description; enabled
  on `rich_body` / `rich_task` only, via `Admin::UploadsController`.
- `LessonImageUpload` policy: image-only, **no SVG** (XSS; diagrams stay the curated
  `public/lesson-images` commit), 10 MB cap.
- Readers get a resized WebP variant (`ruby-vips`); the original is archived.
  `PurgeUnattachedBlobsJob` sweeps orphans.
- **No visible watermark** — it contradicts CC BY-SA, clutters the detail and has no
  SEO value.
- Blobs live in `storage/blobs/`, separate from the SQLite files, with their own
  backup rule ([DEPLOY](../DEPLOY.md)). Not object storage.
