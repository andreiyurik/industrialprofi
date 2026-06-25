# Sourcing — where the world's best practice comes from

## The thesis

The platform's real product is **curated world-best practice, per profession,
localized to the CIS**. This is the librarian model sharpened: we don't write
textbooks and we don't just collect links — we assemble each profession from the
**countries that genuinely lead it**, and point the learner at the source.

In one line: **German structure + American volume + Japanese method + domain
specialists (Netherlands / Norway / Switzerland / Denmark), all anchored to the
CIS standard that is legally required at home.** No single country is "the best" —
the best source is per-trade and per-layer.

## The sourcing filter: quality × openness × translatability

"Best country" is **not** simply "highest quality." A source is only useful to us
if it clears three axes at once:

1. **Quality** — world-class practice in that trade.
2. **Open documentation** — the knowledge is *written down and reachable online*,
   not locked in tacit, mentor-to-apprentice transmission.
3. **Translatability** — we (and the LLM that curates) can actually read it.

This is why **prestige can mislead**: Japan has arguably the highest manufacturing
quality on earth, but much of its deepest knowledge is in Japanese and tacit — so
Japan is a superb source of *method* and a weak source of *linkable documents*.
Chase the intersection of the three axes, not the reputation.

## The hierarchy — apply in this order

1. **CIS standard first** (ГОСТ / СП / ПУЭ / НАКС …) — the legal spine for the
   home market. Non-negotiable where it exists.
2. **Germany — the default structural anchor.** When you need to decide *how to
   structure a trade and what competencies matter*, start here (see below).
3. **USA — the volume & English-depth engine.** For abundant, free, well-explained
   "how to do it well" material and explicit standards.
4. **Japan — the quality method.** For QC, lean, maintenance and robotics
   *philosophy*, mostly via its English-language canon.
5. **Domain specialists** — Netherlands, Norway, Switzerland, Denmark — for the
   specific trades where they, not the big four, are the world reference.

## Country profiles

- **Germany (DE) — our default anchor.** Four reasons it fits *us* specifically:
  the dual vocational system (*duale Ausbildung*) literally writes down a
  step-by-step competency ladder (*Ausbildungsrahmenplan*) — almost a template for
  what we build; it is the homeland of industrial automation (Siemens, KUKA) —
  reinforcing our OT moat; it is the world leader in recycling and the circular
  economy; and its corpus (DIN, VDE, VDI, IHK/HWK) is large, structured, open, and
  translatable.
- **USA (US) — volume and accessibility.** The largest, most accessible
  English-language corpus and the richest set of open standards bodies: ASME,
  IEEE, NFPA, ASHRAE, AWS, ASNT, IPC, ISA, ACI, plus OSHA and endless free video.
  The LLM curates this best. Caveat: US *codes* don't apply in the CIS — borrow
  the knowledge, not the regulation.
- **Japan (JP) — method, not links.** The world reference for quality philosophy
  (TPS / lean, Kaizen, TPM maintenance, 5S, poka-yoke) and robotics (FANUC,
  Yaskawa). Most deep material is Japanese and tacit — reach it through its
  English canon, and use it for *how to think*, not as a primary link source.
- **Switzerland (CH) — premium, small corpus.** Same dual-VET DNA as Germany;
  world-class in precision, rail, construction quality and urbanism. Less open
  material due to size — a sharp supplement to Germany, plus an urbanism reference.
- **Netherlands (NL)** — the world reference for **urbanism / walkable cities /
  water management** and an **agri-tech** powerhouse (precision agriculture).
- **Norway (NO)** — the world leader in **aquaculture / RAS** (salmon).
- **Denmark (DK)** — reference for **cycling urbanism** and wind energy.

## Orient by trade — the operational map

The first column is where to start; the second is the strong supplement. The CIS
standard remains the legal spine for every regulated trade regardless.

| Cluster | First orientation | Second |
|---|---|---|
| Electrical | DE (VDE) | US (NFPA/NEC for knowledge) |
| Welding | US (AWS) | DE + ISO; НАКС for CIS |
| HVAC / refrigeration | US (ASHRAE) | DE |
| **Automation / OT (our moat)** | DE (Siemens ecosystem) | US (ISA, Rockwell) |
| Robotics | JP (FANUC/Yaskawa) | DE (KUKA) |
| NDT / inspection | US (ASNT) | ISO 9712 |
| CNC / machining | DE | JP + US |
| Maintenance / reliability | JP (TPM) | US |
| Electronics / PCB | US (IPC — the global standard) | — |
| Construction / civil | DE (DIN/Eurocodes) | CH (quality), US (ACI) |
| **Urbanism** | NL | CH + DK |
| **Waste / recycling** | DE (the reference) | JP + CH |
| **Aquaculture / RAS** | NO | NL + DK |
| Precision agriculture | NL | US |

Note: NL and NO are not in the "big four" but are the world reference for
urbanism, agri-tech and aquaculture. "Best country" is always per-topic.

## Hard rules

1. **The regulatory layer never transfers.** A German or US *code* is not legal in
   the CIS (NEC ≠ ПУЭ). We borrow the *knowledge and method*; the CIS standard
   stays the legal spine. This is exactly what per-resource `country_code` is for:
   universal knowledge carries no code, country-specific regulation does.
2. **Cite honestly as best-practice, not as a standard.** When the source is a
   foreign association, school, or specialist rather than an official norm, label
   it as proven practice — never dress it up as a binding requirement.
3. **Never invent.** No fabricated "best practices" any more than fabricated ГОСТ
   numbers. Point to a real, verifiable source or flag it for manual review.
4. **One home.** This file is the single home of the sourcing strategy. The
   content prompt (`tools/AUTHOR_PROFESSION.md`) and the backlog reference it —
   they must not copy the map, or it will drift.

## Pointers

- `docs/PROFESSION_BACKLOG.md` — which professions to package (this doc says where
  to source them from).
- `tools/AUTHOR_PROFESSION.md` — the authoring prompt that applies this per lesson.
- `docs/VISION.md` — the librarian model this sharpens.
</content>
