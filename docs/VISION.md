# IndustrialProfi — Vision

**Слоган:** Мастерство не автоматизируется.

**Позиционирование:** Бесплатные карты развития для промышленных специалистов. Официальные стандарты, практические задания, ежедневный прогресс.

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

- **The Odin Project** (theodinproject.com) — the model for everything: content structure (paths → courses → lessons), progress tracking, community-driven content, donation-based business model, design system (dark theme, teal+gold palette, Inter font). What Odin does for web developers, IndustrialProfi does for industrial workers.
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

### Target users:
- Workers in CIS wanting to grow in their profession systematically
- Labor migrants (Uzbekistan, Tajikistan, Kyrgyzstan → Russia, Kazakhstan) who need to prove skills across borders
- Career changers entering industrial trades
- Employers looking for workers with verified, structured knowledge

## Core Mechanics

| Mechanic | Inspiration | Implementation |
|----------|-------------|----------------|
| Profession catalog with roadmaps | roadmap.sh | Stages → skills hierarchy, ERB pages |
| Progress tracking per skill | Khan Academy | Checkboxes, completion %, status bar |
| Official document links per skill | MDN Web Docs | Curated links to standards (ГОСТ, СНиП, ASME, NEC, etc.) |
| Practical tasks per skill | The Odin Project | Text-based assignments, real-world exercises |
| Public user profile | GitHub profile | Completed skills, activity history |
| Community roadmap creation | Wikipedia | Users submit roadmaps, moderation queue |

## Content Strategy — Cold Start

The #1 risk is empty catalog. Solution: **seed 3-5 complete roadmaps before launch.** Not 50 empty ones — 3 thorough ones with real document links and practical tasks.

Each seeded roadmap must have: all stages filled, real standard references, at least one practical task per skill.

## Business Model

**The platform is free.** Supported by community donations (like The Odin Project, Wikipedia).

- Donation link in footer — visible but not intrusive
- Telegram for direct feedback and community building
- Monetization decisions (employer access, premium features) come after real user data and proven value

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
