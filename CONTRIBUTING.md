# Contributing to IndustrialProfi

Thanks for considering a contribution! This project grows in two directions,
and **both matter equally**:

- **Code** — features, fixes, tests, accessibility, performance.
- **Content** — the curated lessons, the ranked links to official standards
  (ГОСТ, ПУЭ, НАКС, ASME), the practical tasks. This is the heart of the
  platform; a great lesson is as valuable as a great pull request.

You can read this guide in your language of comfort — the project is
Russian-first, but English contributions are equally welcome.

## Getting set up

You need **Ruby 4.0.5** and Git. There is no Node.js, no Yarn, no asset build
step to configure.

```bash
git clone https://github.com/yurik2718/industrialprofi.git
cd industrialprofi
bin/setup     # gems, database, sample data
bin/dev       # http://localhost:3000
```

Before opening a pull request:

```bash
bin/rails test     # tests must pass
bin/rubocop        # lint must be clean
```

## How we work

This is a deliberately conventional Rails app. When in doubt, **do what Rails
does by default**, and look at how Basecamp's open-source apps (Writebook,
Fizzy) solve the same problem.

- **HTML-first.** Server-render everything. Turbo Frames for partial updates,
  Turbo Streams for real-time. Stimulus only for behavior that genuinely needs
  client-side JS.
- **ERB only.** No Haml, Slim, or ViewComponent.
- **Skinny controllers, fat models.** Extract to concerns only past ~200 lines.
  No service objects for simple CRUD.
- **RESTful routes.** The 7 standard actions first; custom actions only when
  REST genuinely doesn't fit.
- **i18n from day one.** All user-facing strings via `I18n.t`. Russian first,
  keys in English.
- **Pure CSS** in `app/assets/stylesheets/`, one self-contained file per
  component. No Tailwind, no PostCSS, no `@import` chains, no build step.
- **Minitest + fixtures.** No RSpec, no FactoryBot. Test the critical paths;
  don't test Rails itself.
- **No new gems, patterns, or abstractions** unless Rails genuinely can't do
  the job.

## Pull request flow

1. Fork the repo and create a topic branch (`fix/lesson-completion-toggle`).
2. Make focused commits with clear messages.
3. Make sure `bin/rails test` and `bin/rubocop` pass.
4. Open a PR describing **what** changed and **why**. Screenshots for any UI.
5. A maintainer reviews. Keep the discussion friendly and concrete.

For larger ideas, open an issue first so we can agree on the approach before
you invest the time.

## Contributor License Agreement (CLA)

IndustrialProfi is open source under **AGPL-3.0** and will stay that way. To
keep the project sustainable, a small set of future hosted, employer-facing
features (verified completion certificates, a candidate/employer board) may be
offered commercially — a standard **open-core** model.

So that the project retains the freedom to license its own combined work — for
example, to offer the platform under a commercial license to an organization
that cannot use AGPL — **contributors agree to a lightweight Contributor
License Agreement** when they submit their first pull request.

In short, the CLA means:

- **You keep the copyright to your contribution.** You are not signing it away.
- **You grant the project a license** to use, modify, and relicense your
  contribution as part of IndustrialProfi (including under a future commercial
  license for the hosted product).
- **You confirm** the contribution is your own original work and that you have
  the right to submit it.

This is the same arrangement used by open-core projects like GitLab, Sentry,
and Cal.com. It protects everyone: the code stays open under AGPL for the whole
community, and the project can fund its own development.

A CLA-assistant bot will ask you to accept on your first PR — it's a single
click, recorded once, and applies to all your future contributions.

## Reporting bugs and ideas

Open an issue. For bugs, include steps to reproduce, what you expected, and
what happened. For content, point us at the relevant standard and explain what
should change.

## Code of conduct

Be respectful and constructive. We're building something useful for working
people; keep the tone the same.

---

By contributing, you agree that your contributions are licensed under the
AGPL-3.0 License and the project's CLA as described above.
