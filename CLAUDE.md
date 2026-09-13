@AGENTS.md

## Claude Code

- The `docs/conventions/` pages load automatically through `.claude/rules/` when you read
  matching files; you don't need to open them first.
- After every edit, a hook checks the comment budget of the file. Fix what it reports in
  the same turn.
- Use plan mode before changing a migration, the importer (`lib/curriculum_*.rb`) or
  authentication.
- Delegate broad codebase searches to the Explore subagent. Before handing off a non-trivial
  change, run `/code-review`.
- Do visual checks (browser, screenshots) in a subagent that reports findings as text —
  images stay in context for the rest of the session.
- When compacting, keep the list of modified files, the commands already run and anything
  still unverified.
