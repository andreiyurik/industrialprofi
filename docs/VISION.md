# IndustrialProfi — Vision

**Tagline** (shown in Russian on the site): «Мастерство, практика, документация»
— *Craft, practice, documentation.*

**Positioning:** open development maps for industrial professionals — official
standards, practical assignments, daily progress.

## Problem

Trade professionals have no structured career development platform. Software engineers have roadmap.sh, The Odin Project, freeCodeCamp — industrial workers have nothing. They rely on word of mouth, outdated textbooks, and opaque certification systems.

The pain:
- **Workers** — no clear path from apprentice to expert, no way to prove skills to employers across borders
- **Employers** — can't verify what a candidate actually knows before hiring
- **Migrant workers (CIS)** — millions work in Russia/Kazakhstan with real skills but zero portable credentials

The context: AI is reshaping the job market. Industrial professions — the ones that require physical presence, licensed responsibility, and hands-on judgment — are among the most resilient. But there's no modern platform helping people learn them systematically.

## Solution

A free, open platform for industrial professions. Each profession has a structured roadmap: stages → skills → official documents → practical tasks.

### Primary References

- **The Odin Project** (theodinproject.com) — the model for everything: content structure (paths → courses → lessons), progress tracking, community-driven content, donation-based business model. What Odin does for web developers, IndustrialProfi does for industrial workers. (Visually we follow Basecamp's open-source apps, not Odin's palette.)
- **roadmap.sh** — the model for career path structure: visual profession maps showing what to learn and in what order. We adapt this as text-based stage→skill hierarchies instead of interactive graphs.

### Core Belief

**Read official standards, practice every day.** Not video courses, not AI summaries — real documents that are required on the job site, and real tasks that build muscle memory. This mirrors The Odin Project's philosophy: read the docs, build the projects, learn by doing.

## What This Is NOT

- Not a job board (hh.ru exists)
- Not an online course platform (Stepik, Coursera exist)
- Not a visual graph/flowchart tool (our audience needs clarity, not diagrams)
- Not a social network

It is a **reference + progress tracker**. Content-first, community-driven.

## Target Professions

Focus on professions with proven global demand. BlackRock's $100M Future Builders initiative (March 2026) validated exactly which trades face the sharpest deficit: electricians, plumbers, HVAC technicians, construction workers. We take this signal and adapt it for the CIS market, where the same deficit exists for different reasons — aging workforce, infrastructure boom, labor migration.

### Priority professions (launch roadmaps):

| Profession | CIS certification | Why priority |
|---|---|---|
| **Электрик** (Electrician) | Группы допуска 2-5, ПТЭЭП, ПУЭ | BlackRock's #1 focus; 300K+ shortage globally; mandatory licensing in every country |
| **Сварщик** (Welder) | НАКС, ASME IX, CSWIP 3.1 | Chronic CIS deficit; highest international mobility; 6+ certification standards |
| **Сантехник** (Plumber) | СНиП, СП 30.13330 | BlackRock's #2 focus; every construction site needs them; low barrier to entry |
| **HVAC-техник** (HVAC Technician) | ГОСТ, ПБ 09-592-03 | Growing exponentially with climate change and data center construction |
| **Монтажник** (Steel/Pipe Fitter) | СНиП, СП, допуски СРО | Construction backbone; high turnover = constant demand for qualified workers |

### Next wave (after launch, based on user demand):
- PLC/SCADA technicians (automation)
- CNC operators (manufacturing)
- Industrial mechanics (maintenance)
- Power plant operators (energy)

### Positioning decision (June 2026): narrow wedge, wide ceiling

- **Wedge (today):** industrial trades only. The homepage, tagline and catalog
  speak strictly about what actually exists — a "platform for everything" with
  three maps reads as an empty catalog and burns trust.
- **Ceiling (the vision):** any in-demand profession where hands-on practice
  decides — builders, farmers, mechanics, beyond. The architecture is already
  profession-agnostic (Path/Course/Lesson, expert roles, standards + practice +
  journal carry no "industrial" assumptions).
- **Expansion mechanism: expert-driven, not founder-driven.** The founder
  builds well only what he has worked in (АСУ ТП, industrial). A new profession
  arrives when a real practitioner co-authors its map (trust ladder: suggest
  edits → editor → author, first maps co-built through seeds). The wide vision
  is stated where future co-authors read — the founder letter (/about), the FAQ
  expert item, the public roadmap — NOT in the marketing copy.
- **No renaming.** The IndustrialProfi name may eventually feel narrow for,
  say, farmers — that's a problem for the day a real non-industrial expert
  shows up, not before.

### Target users:
- Workers in CIS wanting to grow in their profession systematically
- Labor migrants (Uzbekistan, Tajikistan, Kyrgyzstan → Russia, Kazakhstan) who need to prove skills across borders
- Career changers entering industrial trades
- Employers looking for workers with verified, structured knowledge

## Core Approach — Why Better Than School

Schools give: theory → exam → diploma. The problem: a person gets a diploma but can't work. Employers know this.

**Our advantage — we remove the middleman.** We don't write our own textbooks. We find the best existing resources (like roadmap.sh) and arrange them in the right order (like The Odin Project). This is the librarian model, not the teacher model.

A school gives a 500-page textbook. We give: "read these 3 pages of ПУЭ and do this task." Concrete, practical, no filler.

### What Makes Users Grateful

1. **Saved time** — no need to search for the right ГОСТы and ПУЭ, we already found them
2. **Clear path** — always visible what's next
3. **Real-world practice** — tasks from actual job sites, not from textbooks
4. **Zero filler** — every lesson has a concrete purpose

## Content Architecture

> **This document is the product intent, not a status ledger.** What has
> actually shipped lives in **git history** and the **Feature map in
> `CLAUDE.md`** — not duplicated here. The codebase conventions live in
> `CLAUDE.md`; the forward roadmap is the "Roadmap & scope" section below.

### Hierarchy: Profession → Course → Lesson

Adapted from The Odin Project (Path → Course → Lesson) for industrial professions:

```
Profession (e.g., Электрик)
├── Course 1: Охрана труда
│   ├── Lesson: Правила безопасности
│   ├── Lesson: Средства защиты
│   └── Lesson: Пожарная безопасность
├── Course 2: Электробезопасность
│   ├── Lesson: Основы электробезопасности
│   ├── Lesson: ПУЭ — Правила устройства электроустановок
│   └── Lesson: ПТЭЭП — Правила технической эксплуатации
└── Course 3: Практические навыки
    └── ...
```

### Lesson Structure — The Core Unit

Every lesson follows this format. This is what makes us more effective than school:

```
1. ЗАЧЕМ (1-2 sentences)
   "This document is required at every job site for work clearance"

2. OFFICIAL DOCUMENTS (curated links, ranked by importance)
   ★ Required:  ПУЭ 7th edition, chapters 1.1–1.3
   ○ Optional:  ГОСТ Р 50571.1-2009

3. PRACTICAL TASK (concrete, verifiable)
   "Create a workplace inspection checklist before starting work
    based on section 1.1.13 of ПУЭ"

4. [✓ MARK AS DONE]
```

The key insight from roadmap.sh: **curated links ARE the content.** We don't write lectures — we find the best official documents and point users to the exact pages they need.

### UX: Roadmap.sh Sidebar Feel + Odin Full Pages

On desktop — two-column layout via Turbo Frames: lesson list on the left, lesson content on the right (like roadmap.sh sidebar). Clicking a lesson loads content without losing the course context.

On mobile — standard page navigation. The sidebar becomes a full page.

One codebase, two presentations. Every lesson has its own URL for SEO and bookmarking.

```
DESKTOP:
┌──────────────────────┬─────────────────────────────┐
│ Электробезопасность  │                             │
│                      │  ПУЭ: Правила устройства    │
│ ✓ Основы             │                             │
│ ✓ Средства защиты    │  Зачем:                     │
│ ● ПУЭ  ← active     │  Основной документ для      │
│ ○ ПТЭЭП              │  любого электрика...        │
│ ○ Допуск             │                             │
│                      │  📄 Документы:               │
│                      │  • ПУЭ 7-е изд. (ссылка)   │
│                      │  • ГОСТ Р 50571 (ссылка)    │
│                      │                             │
│                      │  🔧 Задание:                 │
│                      │  Изучи главы 1.1–1.3...     │
│                      │                             │
│                      │  [✓ Выполнено]              │
└──────────────────────┴─────────────────────────────┘

MOBILE:
Standard page-to-page navigation
```

### Progress Tracking

Binary, like The Odin Project: done or not done. No "in progress", no "pending review". One table: `LessonCompletion(user_id, lesson_id)`. Record exists = done.

Course progress = count of completed lessons / total lessons. Displayed as a progress bar on the profession page.

### What We Take From Each Reference

| Source | What we take | Why |
|---|---|---|
| roadmap.sh | Curated links as core content | Low creation cost, users get the BEST resources |
| roadmap.sh | Sidebar feel (don't lose context) | Turbo Frame two-column layout on desktop |
| The Odin Project | Path → Course → Lesson structure | Proven hierarchy for learning content |
| The Odin Project | Binary progress (done/not done) | Simplicity, no status management overhead |
| The Odin Project | Full pages with own URLs | SEO, bookmarking, mobile-friendly |
| Basecamp/DHH | Design system (black-first dark, monochrome + blue, Inter) | Calm, proven, Cyrillic-ready |
| Basecamp/DHH | ERB + Turbo Frames, no React | Simple, fast, one-person maintainable |

### International Support — Multi-Country Resources

The same profession exists in every country, but the official standards differ. Architecture handles this at the Resource level, not the Path level:

```
Lesson: Правила устройства электроустановок
├── Resource (country_code: nil)  — universal (physics, theory)
├── Resource (country_code: "RU") — ПУЭ 7-е издание
├── Resource (country_code: "KZ") — ПТЭ РК
├── Resource (country_code: "US") — NEC (NFPA 70)
└── Resource (country_code: "DE") — VDE 0100
```

One lesson, one skill, different documents per country. User selects country → sees relevant resources + universal ones. Adding a new country = adding resources, not duplicating lessons.

On MVP: `country_code` field exists on Resource but all values are nil (everything is universal/Russian). When users from Kazakhstan appear — add KZ resources. Zero code changes.

### Official vs Community Content

Two types of roadmaps with clear visual distinction:

**Official** (`author_id: nil`) — created by the platform, verified, shown first. Curated for safety and completeness. These are the core product.

**Community** (`author_id: present`) — created by users, require moderation before publishing. Statuses: `draft → pending_review → published`.

**Safety rule:** In industrial professions, bad advice kills. Community roadmaps MUST be moderated. Users can never edit official roadmaps, but can suggest resources (links) to existing lessons.

```ruby
Path:
  author_id   # nil = official, present = community
  status      # draft | pending_review | published
```

**Phasing:**
- v0.1: Official only (seed data)
- v0.2: Users suggest links to existing lessons (low risk — we moderate links)
- v0.3: Users create full roadmaps (moderate before publish)

## Content Strategy — Cold Start

The #1 risk is empty catalog. Solution: **seed 3-5 complete roadmaps before launch.** Not 50 empty ones — 3 thorough ones with real document links and practical tasks.

Each seeded roadmap must have: all courses filled, real standard references, at least one practical task per lesson.

## Business Model

**Open core, monetization deliberately deferred (founder decision, June 2026).**
The learning platform is free and open-source (AGPL-3.0) — that's the reputation
engine and the acquisition funnel. Two principles are fixed; everything else is
an option to be validated against real users:

1. **The materials are free and open. Forever.** All paths, courses, lessons,
   progress tracking. Never a paywall at the door — money, if any, is charged
   for *outcomes and services around* the content, never for *entry*.
2. **Retention and user satisfaction come before revenue.** The near-term
   metrics that matter are: do people come back, do they complete lessons, do
   they recommend it. A trusted platform can be monetized later; a monetized
   but untrusted one cannot be fixed.

Candidate revenue paths, in rough order of fit (none scheduled — all
demand-gated):

- **B2B — training centers and employers.** Учебные центры use the platform as
  their structured learning environment; предприятия get cohort tracking for
  their own workers (corporate training budgets exist and are mandated by
  labor law). This is where real money in this niche lives. The content the
  companies' workers learn from stays public.
- **Verified completion certificates** (deferred; recorded design below): pay to
  *issue* a verifiable document — learning and verification stay free.
- **Donations:** a footer link, like The Odin Project / Wikipedia — a bonus,
  not the model (donations barely sustain anything in the CIS market).
- Telegram for direct feedback and community building.

### Deferred design — verified certificates (was the v0.4 plan)

Kept so the thinking isn't lost. Trigger to revisit: a real audience, users
*completing* courses, and users asking "is there a document I can show my
employer?" Building before that signal is polishing a paywall around an empty
room.

- **Charges for the outcome, never for entry.** Learning and the public
  `/verify/:token` page stay free forever; payment only *issues* the proof.
- **Honest about what it attests:** *"completed IndustrialProfi's
  standards-based curriculum for X"* — NOT a state license, НАКС attestation, or
  группа допуска (those come from accredited bodies; conflating them is dangerous
  in trades where bad credentials get people hurt).
- **Shape:** all lessons in a course done → eligible → a one-time ~500–1000 ₽
  payment issues a branded PDF with a QR + verification token; the free public
  `/verify` page is the trust anchor and a marketing surface. Payment via a
  CIS-native provider (ЮKassa / CloudPayments / Robokassa — Stripe doesn't work
  in Russia); a webhook flips `paid`.
- **Models:** `Certificate` (`has_secure_token`) + `Payment`; eligibility stays
  *derived* from `LessonCompletion` (no status columns). One fat-model gate:
  `current_user.can_issue_certificate?(course)`.
- **Open-core boundary:** the platform stays AGPL; the hosted issuance +
  verification registry is the commercial layer. Self-hosters run the platform
  freely but can't mint *IndustrialProfi-verified* certificates — the moat is the
  registry + brand, not the code.

## Roadmap & scope

What shipped (v0.1 static catalog, v0.2 accounts/progress, and a large set of
editor/admin/retention features built ahead of plan) lives in **git history** and
the **Feature map in `CLAUDE.md`** — not duplicated here. This section is
forward-looking only.

### Next — v0.3 (not built)

The "self-developing platform" milestone — content grows through other people,
not the founder:

- **Community-authored roadmaps:** an in-app create flow (profession → course →
  lesson → resources/task) with `draft → pending_review → published`; admins
  publish. The suggest-edit → review → immutable-revision pipeline and the
  `member → editor → administrator` trust ladder already exist as the foundation.
- **Search** across professions, courses, and lessons (also the home for the
  deferred command palette).
- **Public user profiles** — completed paths and authored/contributed content.
- **Moderated public portfolio** — publishing selected journal entries as a
  public showcase; media, if added, goes **off-disk** (object storage), never
  onto the private `JournalEntry` or the SQLite disk.

### Explicitly not building (until real users ask)

| Feature | Why not now |
|---|---|
| Visual graph/flowchart | The audience needs lists, not diagrams |
| Streak/gamification | Optimizing retention before acquisition is premature |
| Badges/certificates | Needs trust and volume first — see the deferred design above |
| Mobile app | Responsive web is enough for years |
| API | No consumers exist yet |
| Multi-language sync | Russian first; each market gets its own paths, not synced translations |
| Employer portal / candidate marketplace | Need a real user base with profiles first |
| Payment system | Free until the model is proven; first use is the deferred certificate |
| Comments / discussions / forum | Forum dynamics are hard — add only if users ask |
| AI features | A distraction from core content value |
| Realtime chat / floating widget | A solo founder can't honor chat expectations — async feedback wins |

## Principles

1. **Content over features.** 3 great roadmaps beat 50 features with no content.
2. **Ship weekly.** Every Friday the deployed version is better than last Friday.
3. **Official standards first.** Link to real documents, not summaries. Workers need what's required on the job site.
4. **Practice daily.** The platform encourages consistent, daily practice — not binge learning.
5. **No JS where HTML works.** Hotwire for interactivity, Stimulus only when server can't solve it.
6. **Russian-first, international-ready.** UI in Russian, i18n from day one, English later.
7. **One person can run it.** SQLite, single server, Kamal deploy. No DevOps team needed.

## Feedback & Support

- **Telegram:** direct line to the creator for feedback, suggestions, bug reports
- **Donate page:** for users who want to support the project's development
- Both linked in the site footer
