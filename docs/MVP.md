# Phased Rollout

Each phase is a deployable, usable product — not a prototype.

> **Implementation status (read before trusting the data-model bullets below).**
> The phase plans are the original intent; some model names and choices evolved
> during build. Current reality (source of truth: `db/schema.rb` + `app/models/`):
> - **Naming evolved:** `Profession → Path`; the `Stage`/`Skill`/`Task` split
>   collapsed into a single **`Lesson`** (with a `stage` *string* for grouping and
>   `body`/`task`/`description` rich-text sections); `Tailwind → pure CSS`.
> - **Shipped (~v0.1):** static published catalog (`Path → Lesson → Resource`),
>   SEO (sitemap, JSON-LD), markdown/ActionText content, Kamal deploy.
> - **Shipped ahead of plan:** an admin panel for editing lessons, a reader
>   **suggestion** flow, and an append-only **revision** history
>   (`LessonSuggestion`, `LessonRevision`, `RevisionDiff`).
> - **Shipped (v0.2):** `User` + `Session` + `Current` (Writebook pattern,
>   `has_secure_password`), binary `LessonCompletion` ("mark as done" via Turbo
>   Stream — no `UserProgress` statuses, no `UserRoadmap`: "started" is derived
>   from having ≥1 completion), per-stage/per-path progress bars, `/dashboard`
>   with continue links, the desktop two-column lesson sidebar, and admin folded
>   into a `role` flag on `User` (HTTP Basic removed; first admin via
>   `ADMIN_EMAIL`/`ADMIN_PASSWORD` env at seed time or console).
> - **Also shipped:** password reset (token + mailer; production needs SMTP),
>   `/projects` (aggregated practice lessons), stage-milestone chips +
>   completion celebrations, and the numbered journey rail on path pages.
> - **Not built yet:** v0.2's profile page (name/profession/city); all of v0.3
>   (community roadmaps, search, public profiles, project submissions).

## v0.1 — Static Catalog (Target: 1 week)

A visitor can browse profession roadmaps. No auth, no interactivity. Pure content.

**What ships:**
- Landing page with project description
- Catalog page listing 3 professions
- Profession show page: stages → skills list (collapsible)
- Each skill shows: description, official document links, practical task text
- Responsive layout (Tailwind), dark mode support
- Deployed to production via Kamal

**Data model:**
- `Profession` (title, slug, description, locale)
- `Stage` (profession_id, title, position)
- `Skill` (stage_id, title, description, position)
- `Resource` (skill_id, title, url, kind: document|video|article)
- `Task` (skill_id, description)

**Seeded content (priority professions aligned with BlackRock Future Builders deficit data):**
- Электрик (группы допуска 2-5) — full roadmap with ПТЭЭП, ПУЭ links
- Сварщик НАКС — full roadmap with ГОСТ, ASME links
- Сантехник — full roadmap with СНиП, СП links

**What does NOT ship:**
- No user accounts
- No progress tracking
- No user-generated content
- No search

**Deploy criteria:** an electrician in Omsk can open the site on mobile, read the full roadmap for their profession, and find links to real documents they need.

---

## v0.2 — User Accounts + Progress (Target: 2 weeks after v0.1)

Registered users track their learning progress.

**What ships:**
- Registration/login (has_secure_password, session-based)
- User profile page (name, profession, city)
- "Mark as completed" on each skill (Turbo Stream, no page reload)
- Progress bar per stage and per profession
- Dashboard: "My roadmaps" with completion stats

**Data model additions:**
- `User` (email, password_digest, name, city, locale)
- `UserProgress` (user_id, skill_id, status: todo|in_progress|completed, completed_at)
- `UserRoadmap` (user_id, profession_id) — "I'm studying this"

**What does NOT ship:**
- No social features (comments, follows)
- No user-generated roadmaps
- No admin panel (seed data, manage via console)

**Deploy criteria:** a user registers, picks "Сварщик НАКС", marks skills as done, sees their progress percentage. Comes back next day — progress is saved.

---

## v0.3 — Community Content (Target: 3-4 weeks after v0.2)

Users contribute roadmaps. Platform becomes self-sustaining.

**What ships:**
- "Create roadmap" form (profession → stages → skills → resources → tasks)
- Draft/published states for user roadmaps
- Basic moderation: admin approves before publishing
- Search across professions and skills
- Public user profiles (completed roadmaps, authored roadmaps)
- Basic SEO (meta tags, sitemap, structured data for Google)

**Data model additions:**
- `author_id` on Profession (nullable — nil = platform-seeded)
- `status` on Profession (draft|published)
- Admin role on User

**What does NOT ship:**
- No reputation system
- No badges or gamification
- No employer-facing features
- No API

**Deploy criteria:** a user creates a roadmap for "Токарь ЧПУ", submits for review. Admin approves. Other users can find it in the catalog and track progress.

---

## v0.4 — Verified Certificates (first paid feature) — DEMAND-GATED, NOT scheduled

> **This phase ships only when reality says so**, not on a timer. The trigger is:
> there is a real audience, users are *completing* courses, and they are asking
> "is there a document I can show my employer?". Building this before that signal
> means polishing a paywall around an empty room. Until then, this section is a
> recorded decision, not a task.

This is the **first paid feature** and the project's first real monetization.
It sits squarely inside the open-core model: **the platform stays free and
open-source under AGPL; the hosted certificate-issuance and verification
registry is the commercial layer.** Money is charged for the *outcome* (a
verifiable proof of completion), never for *entry* — learning is always free.

**The honest premise.** The engineering here is the easy 20% — generating a PDF
and gating it is a day of work. The hard 80% is **trust**: a certificate is
worth exactly what employers believe it's worth. So this phase is as much a
distribution/partnership effort as a coding one, and it must be honest about
what it attests.

- It certifies: *"completed IndustrialProfi's standards-based curriculum for X."*
- It does **NOT** certify: a state license, НАКС attestation, or a группа допуска.
  Those are issued by accredited bodies. Conflating the two would be dishonest
  and dangerous in trades where bad credentials get people hurt.

**What ships:**
- A user who has completed **every lesson in a course** becomes eligible for a
  certificate. (Completion stays free and visible on the profile — unchanged.)
- A one-time payment (~500–1000 ₽) **issues** an official, branded PDF
  certificate carrying a unique verification token and a QR code.
- A **public, free** verification page `/verify/:token` — anyone (an employer)
  can confirm a certificate is genuine. This page is free, indexable, and is
  both the trust anchor and a marketing surface. Verification never costs money.
- Payment via a CIS-native provider (**ЮKassa / CloudPayments / Robokassa** —
  Stripe does not work in Russia). A webhook flips the payment to `paid`.

**Data model additions:**
- `Certificate` (user_id, course_id, verification_token, issued_at) —
  `has_secure_token :verification_token`; created on successful payment.
- `Payment` (user_id, certificate_id, amount_cents, provider, status, paid_at) —
  the provider webhook sets `status: "paid"`.
- Course completion is still *derived* from `LessonCompletion` counts; no new
  status columns, no `in_progress`. Eligibility = all lessons in the course done.

**The single gate** (one line, fat-model, no service object):
```ruby
# Free to learn; pay only to issue the proof.
current_user.can_issue_certificate?(course)  # => all lessons done && payment.paid?
```

**Open-core boundary:**
- Open & AGPL: the whole learning platform (paths, courses, lessons, progress).
- Commercial (future `ee/`, separate license + CLA-protected): hosted
  certificate issuance and the verification registry. Self-hosters can run the
  platform freely; they cannot issue *IndustrialProfi-verified* certificates,
  because the trust registry lives on the canonical hosted instance. The moat
  is the registry + brand, not the code.

**What does NOT ship in v0.4:**
- No subscriptions, no employer board, no candidate marketplace (that's a later
  phase, and only after this one proves people pay for the outcome).
- No proctored exam — the certificate attests *curriculum completion*, not a
  supervised assessment.

**Risks & honest mitigations:**
- *"A certificate nobody recognizes is worthless."* → Keep verification free and
  public; pursue recognition through учебные центры / employer partnerships; be
  precise in wording about what it attests. Recognition is earned, not shipped.
- *Refund/chargeback abuse* → certificate is issued only after the webhook
  confirms payment; revocation flips a flag and the `/verify` page reflects it.

**Deploy criteria:** a welder finishes the "Сварка: подготовка к аттестации"
course, pays 500 ₽, downloads a PDF with a QR code. An employer scans it, lands
on a free `/verify` page, and sees: *"Иван Иванов completed «Сварка: подготовка
к аттестации», 14.03.2027 — verified by IndustrialProfi."*

---

## Explicitly Not Building (Until Real Users Ask)

| Feature | Why not now |
|---------|------------|
| Visual graph/flowchart | Target audience needs lists, not diagrams |
| Streak/gamification | Retention optimization before acquisition is premature |
| Badges/certificates | Needs trust and volume first — planned as paid **v0.4**, demand-gated |
| Mobile app | Responsive web is enough for years |
| API | No consumers exist yet |
| Multi-language | Russian first, English when there's demand |
| Employer portal | Need 5K+ users with profiles first |
| Payment system | Free until business model is proven — first use is the **v0.4** certificate (pay for the outcome, never for entry) |
| Comments/discussions | Forum dynamics are hard — add only if users ask |
| AI features | Distraction from core content value |
