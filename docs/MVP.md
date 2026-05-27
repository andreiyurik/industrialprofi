# Phased Rollout

Each phase is a deployable, usable product — not a prototype.

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

## Explicitly Not Building (Until Real Users Ask)

| Feature | Why not now |
|---------|------------|
| Visual graph/flowchart | Target audience needs lists, not diagrams |
| Streak/gamification | Retention optimization before acquisition is premature |
| Badges/certificates | Needs trust and volume first |
| Mobile app | Responsive web is enough for years |
| API | No consumers exist yet |
| Multi-language | Russian first, English when there's demand |
| Employer portal | Need 5K+ users with profiles first |
| Payment system | Free until business model is proven |
| Comments/discussions | Forum dynamics are hard — add only if users ask |
| AI features | Distraction from core content value |
