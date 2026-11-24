---
summary: Warm-paper light and graphite dark themes from one token set; default follows the OS, a footer switch overrides it.
paths:
  - "app/assets/stylesheets/colors.css"
  - "app/views/shared/_theme.html.erb"
  - "app/views/shared/_theme_switch.html.erb"
  - "app/javascript/controllers/theme_controller.js"
date: 2026-11-24
status: accepted
revisit_when: Metrika shows almost nobody uses one of the two themes
---

# Light and dark themes

The single dark theme is replaced by two. Light is warm paper (`oklch(97.5% 0.012 85)`)
with graphite ink, ~15:1; dark is graphite (`oklch(19% 0.008 250)`) with warm off-white
ink, ~13.7:1. `:root[data-theme="light"]` overrides primitives only, so components stay
theme-agnostic. The head script always sets `data-theme`, resolving «auto» from the OS;
the footer switch (auto / light / dark) stores the choice in `localStorage`, not a cookie,
because lesson pages answer with `fresh_when` ETags that don't vary by cookie. Safety
orange `--color-signal` marks «важно» callouts, hi-vis yellow is the text selection, and
lesson prose is 17px / 1.65 on desktop.

**Why.** Positive polarity (dark text on light) reads faster and more accurately for long
text (Piepenbrock et al., 2013), and light-on-dark halates for readers with astigmatism;
dark still helps in low light and some readers prefer it, so both stay. The old flat gray
felt cold; a little warmth in the neutrals keeps it industrial but comfortable.

Related: [CSS conventions](../conventions/css.md).
