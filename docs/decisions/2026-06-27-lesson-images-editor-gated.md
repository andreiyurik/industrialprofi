---
summary: Lesson image upload is editor-only (rich_body/rich_task), image-only, no SVG, 10 MB, WebP variants, no watermark, blobs on local disk; web-filled placeholders go to blobs too.
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

## 2026-09-01: web-filled placeholders go to blobs, not git

- A pending placeholder («Иллюстрация готовится») shows the profession's editors a fill
  link (`.lesson--fillable`, CSS-reveal, no JS). It and the `/admin/illustrations` queue
  lead to `admin/lessons/:slug/illustrations/new`: the brief plus one file field.
- `Lesson#fill_illustration!` swaps the exact `TODO`/`placeholder:` src for a permanent
  blob proxy URL and writes the revision directly — the revision diff is blind to a src
  change.
- Production can't write to `public/` (immutable image), so web-filled images are
  `lessons.illustrations` attachments, transcoded once to bounded WebP
  (`LessonImageUpload.reader_ready_blob`). Files already committed under
  `public/lesson-images` stay; the census resolves both.
- Debt: `content:export` doesn't carry blob images into packs yet.
