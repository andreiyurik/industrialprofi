---
summary: Node runs Herb's ERB linter on laptops and in CI; the app, its assets, build and deploy stay Node-free.
date: 2026-10-02
status: accepted
revisit_when: Herb's linter ships a Ruby-native CLI, or a second Node tool is proposed
---

# Node for dev tools only

Node is a development and CI tool, pinned in `.tool-versions`. It runs Herb's ERB linter
(`bin/herb-lint`, at the version `.herb.yml` pins) locally and in `bin/ci`. It never enters
the app runtime, the asset pipeline, the build or the deploy: importmap stays, and there is
no `package.json`. The Ruby `herb` gem runs `bin/herb analyze .` in CI, so every template
parses and compiles with `Herb::Engine`, which Rails 8.2 brings to the view layer.

**Why:** Herb's linter, formatter and language server are TypeScript, while only the parser
and engine ship in the gem. Node is a standard tool that costs a contributor one `mise
install`; the server's running cost is unchanged because nothing ships to production.

Related: [JavaScript conventions](../conventions/javascript.md),
[Herb](https://herb-tools.dev).
