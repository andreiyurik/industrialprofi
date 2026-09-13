---
summary: Spacing primitives stay at three sizes; near-miss literals (container gutters, the 0.75rem cluster) stay literal on purpose.
date: 2026-07-31
status: accepted
revisit_when: new near-miss cases actually recur in fresh work
---

# Spacing primitives stay at three sizes

After swapping every exact-match `margin`/`padding`/`gap`/`inset` literal for
`--block-space`/`--inline-space`, the near-misses were left literal: `layout.css`
`.container`/`.section` gutters and ~30 similar inline-axis spots (a real axis/unit
mismatch), plus a recurring `0.75rem` cluster. A value repeating is not a reason for
a fourth tier.
