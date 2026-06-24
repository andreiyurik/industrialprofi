<div align="center">

# IndustrialProfi

A free, open-source learning platform that teaches industrial professions
the way real craftsmen actually learn: by reading official standards
(ГОСТ, ASME, НАКС) and doing verifiable, real-world practice.

[![CI](https://github.com/yurik2718/industrialprofi/actions/workflows/ci.yml/badge.svg)](https://github.com/yurik2718/industrialprofi/actions/workflows/ci.yml)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Content: CC BY-SA 4.0](https://img.shields.io/badge/Content-CC%20BY--SA%204.0-lightgrey.svg)](LICENSE-CONTENT)
[![Ruby 4.0](https://img.shields.io/badge/Ruby-4.0-CC342D.svg)](.ruby-version)
[![Rails 8.1](https://img.shields.io/badge/Rails-8.1-D30001.svg)](Gemfile)

[Vision](docs/VISION.md) · [Roadmap](docs/VISION.md#roadmap--scope)

</div>

---

## Why this exists

The Odin Project proved that people can master full-stack web development for
free — not through video courses, but by reading documentation and building
real projects. **IndustrialProfi brings that model to the trades.**

Welders, electricians, instrumentation techs and other industrial workers in
the CIS (Russia, Kazakhstan) have no structured, free, standards-based path to
grow their skills. The official knowledge already exists — it lives in ГОСТ,
ПУЭ, НАКС and ASME standards — but it's scattered, intimidating, and unmapped.
IndustrialProfi curates it into clear career roadmaps:

```
Profession  →  Course           →  Lesson
(Электрик)     (Охрана труда)      (ПУЭ: Правила устройства электроустановок)
```

## How a lesson works

Every lesson follows the same honest, no-fluff structure — the same idea as
an Odin Project assignment, adapted for the shop floor:

1. **WHY** — one or two sentences on why this matters on the job site.
2. **OFFICIAL DOCUMENTS** — curated links to the real standards, ranked
   (★ required, ○ optional). No paraphrasing — you read the source.
3. **PRACTICAL TASK** — a concrete, verifiable assignment.
4. **✓ Mark as done** — binary progress, just like Odin. Done or not done.

Course progress is simply `completed / total`. No "in progress", no fake
gamification — just a clear map of what you know and what's next.

## Tech stack

This is a deliberately boring, **build-step-free** Rails app — and that's the
point. It's a reference for how much you can ship with vanilla Rails 8 and
Hotwire, no Node.js anywhere in sight.

- **Ruby 4.0 / Rails 8.1**
- **SQLite3** + Solid Queue, Solid Cache, Solid Cable
- **Hotwire** (Turbo + Stimulus) — server-rendered HTML, no SPA
- **Pure CSS**, served as-is by **Propshaft** — no Tailwind, no PostCSS, no
  bundler, no build. The cascade is just filenames in alphabetical order.
- **Importmap** — no Node, no Webpack, no Vite
- Auth via `has_secure_password` (bcrypt) — no Devise
- **Kamal 2** + Docker + Thruster for deploys
- **Minitest** + fixtures + Capybara
- Self-hosted Inter / Inter Tight via `@font-face`, OKLCH color tokens, a
  single black-first dark theme — UI patterns mirror Basecamp's open-source
  apps (Writebook, Fizzy).

## Getting started

You need Ruby 4.0.5 and Git. No Node, no Yarn, no asset pipeline to configure.

```bash
git clone https://github.com/yurik2718/industrialprofi.git
cd industrialprofi
bin/setup          # installs gems, prepares the database, seeds sample data
bin/dev            # starts the server at http://localhost:3000
```

Common tasks:

```bash
bin/rails test          # run the test suite
bin/rails test:system   # system tests (Capybara)
bin/rails db:migrate    # run migrations
bin/rubocop             # lint
```

## Project structure

```
app/models/                 # domain models (Path, Course, Lesson, ...)
app/controllers/            # RESTful controllers, render ERB
app/views/                  # ERB templates + Turbo Frame/Stream partials
app/javascript/controllers/ # Stimulus controllers
app/assets/stylesheets/     # all CSS — one self-contained file per component
db/migrate/                 # migrations = source of truth for schema
docs/                       # VISION.md, DEPLOY.md (English project docs)
tools/                      # reusable content-authoring tools (content tooling)
```

Content hierarchy:

```
Path (profession)  →  Course  →  Lesson  →  Resource (links to standards)
User  →  LessonCompletion  (binary: the row exists = the lesson is done)
```

## Roadmap

IndustrialProfi ships in phases — the forward roadmap lives in
[docs/VISION.md → Roadmap & scope](docs/VISION.md#roadmap--scope):

- **v0.1 — shipped:** static catalog (professions → courses → lessons, public, SEO-first)
- **v0.2 — shipped:** accounts, binary progress, dashboard, practice journal,
  activity heatmap, reader suggestions + revision history, admin panel with roles
- **v0.3 — next:** community-authored content (draft → review → published),
  search, public profiles

The user-facing roadmap lives at `/roadmap` on the site itself; the full product
thinking lives in [docs/VISION.md](docs/VISION.md).

## Contributing

Contributions are welcome — whether you write code or curate the content that
actually teaches people. Start with [CONTRIBUTING.md](CONTRIBUTING.md).

A quick heads-up on the model: the **platform is and stays open source** under
AGPL-3.0. A small set of future hosted, employer-facing features (verified
completion certificates, a candidate/employer board) may be commercial — this
is a classic **open-core** setup. Contributors sign a lightweight CLA so the
project keeps the freedom to sustain itself; details in `CONTRIBUTING.md`.

## License

IndustrialProfi is **dual-licensed**:

- **Code** — [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0).
- **Content** — the curriculum and lessons are licensed under
  [Creative Commons Attribution-ShareAlike 4.0](LICENSE-CONTENT) (CC BY-SA 4.0).

In plain terms: you're free to use, study, share and modify the **code** — and
if you run a modified version as a network service, you must make your source
available too. The **learning content** you're free to share and adapt (even
commercially), as long as you credit IndustrialProfi and keep it under the same
license. Third-party standards (ГОСТ, ASME, НАКС…) are only linked or cited and
remain their publishers' property.

## Acknowledgements

Standing on the shoulders of projects that showed the way:

- **[The Odin Project](https://www.theodinproject.com/)** — the open-curriculum
  model and the read-the-docs-then-build philosophy.
- **[roadmap.sh](https://roadmap.sh/)** — structured, visual career roadmaps.
- **[Basecamp](https://github.com/basecamp)** — the open-source Rails apps
  (Writebook, Fizzy, Once-Campfire) whose design and code conventions this
  project follows.

---

<div align="center">
Built for the people who keep the lights on, the pipes welded, and the machines running.
</div>
