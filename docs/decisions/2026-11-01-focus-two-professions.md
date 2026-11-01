---
summary: Only «Инженер АСУ ТП» and «Электрик» stay in the catalog; the other professions are unlisted, not unpublished, and calculators join the header.
date: 2026-11-01
status: accepted
revisit_when: two months of Metrika goals are in, or an unlisted profession out-draws a listed one in entry visits
---

# Focus on two professions

The catalog, dashboard suggestions, practice, library, glossary and calculator index
show only «Инженер АСУ ТП» and «Электрик». The other seven professions get
`paths.listed = false`, which is not `draft`: their hubs, lessons and calculators stay
public by URL, in the sitemap and in site search, with a notice pointing to the two. An
administrator flips the flag in the profession form. Calculators move into the header
nav, and Metrika counts four goals: `signup`, `lesson_completed`, `calculator_used`,
`link_copied`.

**Why.** Metrika for August–November 2026 (~570 visitors, 65 returning) showed where
the readers are. The top lessons are all АСУ ТП (cabinet schematic 57 views, 4–20 mA 56,
FSA 49), and calculators are the largest search entry (ma-scaling 37, modbus-rtu 26,
twisted-pair-line 19). By hub views АСУ ТП led with 84, then Электрик 53 and ЧПУ 50.
This replaces «electrician first» in
[users before features](2026-09-21-users-before-features.md) with the two professions
readers already pick. Unpublishing would 404 lessons that already earn search visits
(ЧПУ «887н», 16 entries), so the flag hides lists only.

Related: [hobby shelf](2026-09-27-hobby-shelf.md),
[narrow wedge, wide ceiling](2026-06-12-narrow-wedge-wide-ceiling.md).
