---
summary: Admin dashboard and action log, user card, feedback line, gem-free error monitoring, analytics, and the public contribute/partners/business pages.
paths:
  - "app/controllers/admin/**"
  - "app/models/admin_action.rb"
  - "app/models/system_status.rb"
  - "app/models/mail_metrics.rb"
  - "app/models/weekly_counts.rb"
  - "app/models/feedback.rb"
  - "lib/error_subscriber.rb"
  - "app/jobs/disk_alert_job.rb"
  - "app/controllers/feedbacks_controller.rb"
  - "app/controllers/business_inquiries_controller.rb"
  - "app/controllers/pages_controller.rb"
---

# Admin and operations

Everything here is gated by `can_edit_content?` / `can_administer?`. No admin gems, no
charting JS.

- **Dashboard** (`/admin`): signups 12-week CSS bar chart, active this week, pending
  suggestions, completions, journal volume, content health, and `SystemStatus` vitals
  (disk + SQLite footprint, Solid Queue health, `MailMetrics`). Plain group/count
  queries; the scaling seam is `Rails.cache.fetch`.
- **Action log** (`/admin/log`): `AdminAction` — append-only record of role changes,
  grants, approvals/rejections, rollbacks, suspensions and live-content lesson changes.
  Denormalized `details` JSON, keyset pagination, category/actor filters, no free-text
  search. Written through `Admin::BaseController#record_admin_action`.
- **User card** (`/admin/users/:id`): profile, role/suspend controls, progress, active
  sessions (force logout), recent activity.
- **Feedback line** («Написать автору»): async `Feedback` → `/admin/feedbacks` (unread
  badge) + an email per message. Not a chat ([decision](../decisions/2026-06-24-no-realtime-chat.md)).
- **Error monitoring**: `ErrorSubscriber` on `Rails.error` emails administrators on
  unhandled exceptions, throttled via Solid Cache. No Sentry — this plus an external `/up`
  ping is the whole story.
- **Analytics**: Yandex Metrika only when `YANDEX_METRIKA_ID` is set (`shared/_metrika`),
  idle-loaded, a hit per `turbo:load`. Disclosed in `/privacy` — keep it truthful. GA
  rejected (152-ФЗ, no Google Ads in RU).
- **Public pages**: `/contribute` (participation, the wanted-professions board from
  `ru.yml → contribute.wanted`), `/partners` (sponsors, independence firewall),
  `/business` (a B2B demand sensor: pitch + inquiry form → tagged guest `Feedback`; the
  paid offer is on-prem deploy + closed training maps; build B2B features only from real
  repeated inquiries).
