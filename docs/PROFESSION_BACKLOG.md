# Profession backlog — the priority list

The operational to-do of which professions to package next, and in what order.
This is a **living, status-bearing** document — distinct from `VISION.md`, which
owns the *positioning* (why industrial trades, the narrow-wedge / wide-ceiling
rule). This file owns the *queue*.

**The defining filter: knowledge-deep professions with a real shortage of
*quality* people.** Those two — depth + a quality deficit — are the hard gates.
Heavy standardization/regulation is the **preferred spine, not a requirement**:
where official documents exist (ГОСТ/СП/ISO/ASME…) they're the backbone you read;
where they're thin — common for hands-on trades — we substitute the **proven best
practice of the world's top specialists** (Germany, Japan, the Netherlands, the
US…), curated and **honestly cited as best-practice, never invented**. The filter
is still a *negative* tool: it rejects the *shallow* and the *un-sourceable* (not
the merely unregulated), and a domain like construction enters only **decomposed**
into deep professions, never one shallow «Строительство» path.

It doubles as the **"wanted professions" board** for future co-authors: per
VISION, expansion is expert-driven — a profession moves up the list the day a
real practitioner co-authors it (`/contribute`). Don't read it as a founder
commitment to build all of this alone.

This file says *which* professions; **`docs/SOURCING.md` says *where* to draw each
one's best practice from** (by country and trade).

> The demand/deficit framing below is reasoned curation from well-established
> labour-market trends (aging trades workforce, the energy transition,
> manufacturing reshoring, the AI/data-centre build-out, the cold chain), not
> freshly-pulled statistics. Ask if you want a sourced deep-research pass on any
> specific candidate before investing in it.

## A profession earns a slot only if it clears all five

1. **Real deficit of *quality*.** A structural shortage of genuinely skilled
   people — not just warm bodies but competent ones — and the gap is widening.
2. **Spirit-fit.** You become competent by *reading the best available sources and
   doing verifiable practice* (the librarian model) — official standards where
   they exist, otherwise the curated best practice of the world's top specialists.
   Hands-on, safety- or quality-critical. Not a soft-skill field, not pure desk
   theory.
3. **Depth.** A real ladder from apprentice to expert, backed by a real body of
   knowledge — standards (ГОСТ / СП / ISO / ASME / IEC) and/or the documented best
   practice of recognized experts. If it fits in five lessons, it's a course
   inside a profession, not a profession.
4. **Packageable cheaply.** The sources are public and linkable, and the practice
   scales from safe paper/bench work up to real tools — so we can build and host
   it without per-lesson cost (the north star). Manual trades fit this well: the
   verifiable practice is real work you can photograph into the journal.
5. **CIS-anchored.** It serves the CIS market first — where official standards
   exist they're Russian/Kazakh (Ростехнадзор, НАКС…); where we lean on world
   best-practice, we localize it to CIS reality. Universal knowledge travels to
   other countries later via per-resource `country_code`.

## Status legend

- **Live** — seeded with substantial real content, `status: published`.
- **Draft** — real content seeded but not yet public (`status: draft`).
- **Planned** — not started. There is **no empty-stub state**: a profession with
  no content gets no seed directory and no `Path` row (both would be pure admin
  noise). Until someone writes it, it exists only as copy — on the catalog's
  vacancy board (`ru.yml → paths.soon_wanted`), on `/contribute`
  (`contribute.wanted`) and here.

## Tier 1 — core hands-on trades (the wedge)

The classic deficit trades that validate the model. Build breadth here only as
far as it stays high-quality; depth beats a long shallow catalogue.

| Profession | Status | Deficit driver | Depth anchor |
|---|---|---|---|
| **Электрик** (Electrician) | **Live** (`elektrik`) | Mandatory licensing everywhere; aging workforce | ПУЭ, ПТЭЭП, группы допуска 2–5 |
| **Сварщик** (Welder) | **Live** (`svarshchik`) | Chronic global shortage; highest international mobility | НАКС, ГОСТ, ISO 9606, ASME IX |
| **Холодильщик / HVACR** (Refrigeration & HVAC) | **Planned** | Cold chain + data-centre cooling + climate | F-gas/refrigerant regs, ГОСТ, EN 378 |
| **Сантехник / трубопроводчик** (Plumber / pipefitter) | **Draft** (`slesar-santehnik`) | Every construction site; low entry, high need | СП 30.13330, СНиП |
| **Автомеханик** (Automotive technician) | **Live** (`avtomehanik`) | Every town has the demand; the diagnostician half is scarce everywhere | ГОСТ 33997-2016 (superseded ГОСТ Р 51709-2001 in 2018), ТР ТС 018/2011, OBD-II — *teach diagnosis (scanner, scope, CAN), not part-swapping; a vendor manual is not a profession*. Engine rebuild, alt-powertrain (gas/hybrid/EV) and motorcycle service ship as separate `coming_soon` course specializations, not folded into the core path. |

## Tier 2 — industrial automation / OT cluster (our moat)

**The strongest angle.** This is where the app already has real depth, where the
founder's own expertise lives, and where the niche is defensible — generic IT
education is saturated (The Odin Project, freeCodeCamp), but *industrial* OT is
underserved and deep. Keep every entry here framed through the
industrial/OT lens; the moment one drifts into generic IT it loses the wedge.

| Profession | Status | Deficit driver | Depth anchor |
|---|---|---|---|
| **Инженер АСУ ТП** (Industrial automation / ICS) | **Live** (`inzhener-asu-tp`) | Automation everywhere; few who can commission it | PLC, SCADA, Modbus/OPC UA, IEC 61131-3 — 2026-07-31 quality audit confirmed no gap large enough to justify a separate profession for vendor-PLC depth or HMI/SCADA-software depth; a generic "Инженер КИПиА" would also fully overlap the existing field-instrumentation course. Dropped from the public "planned" board on that basis. If Siemens TIA Portal, Allen-Bradley/Rockwell, CODESYS or HMI/SCADA-software depth is ever built, it belongs as a `coming_soon` course specialization inside this path (same pattern as `avtomehanik`), not a separate profession — no stub course exists yet, add one only when real content is being authored. |
| **КИПиА** (Instrumentation & control, incl. АЭС) | **Live** (`kipia-aes`) | Metrology + functional safety scarce | СИ/поверка, SIL, IEC 61508/61511, НП-001 |
| **Безопасность АСУ ТП** (ICS/OT cybersecurity) | **Planned** | Acute, very current; regulated | IEC 62443, ФСТЭК приказы — genuinely separate job market/certification track from `inzhener-asu-tp`, not a course fold; build it on the `kipia-aes` delta pattern (base from АСУ ТП, own profession for the security-specific layer) |
| **Промышленные сети** (Industrial networking) | **Live, folded into `inzhener-asu-tp`** | OT/IT convergence | Industrial Ethernet, PROFINET, Modbus TCP, OPC UA — already shipped as the `04-promyshlennye-seti` course inside the ASU ТП path; this row is stale as a standalone "Planned" entry and should not be re-proposed as a separate profession |
| **Linux/edge для автоматики** (Edge Linux for automation) | **Planned** | Edge compute in АСУ ТП | *keep tied to SCADA/edge gateways, else it competes with TOP and dilutes the niche* — public board entry (`ru.yml` soon_wanted / contribute.wanted) renamed 2026-07-31 from generic "Системный администратор Linux" to "Linux для промышленной автоматизации" to match this scoping |
| **Робототехника / интеграция роботов** (Industrial robotics) | **Planned** | Automation + reshoring; integrators scarce | ISO 10218, ISO 13849 safety; KRL/RAPID; offline sim — *teach standardized integration & safety, name KUKA/FANUC/ABB as tools, don't be a vendor manual* |

## Tier 3 — deep certification trades (best standards-fit, clear deficit)

Standards-heavy, certification-laddered, cross-industry — almost tailor-made for
the read-the-standard + practice format.

| Profession | Status | Deficit driver | Depth anchor |
|---|---|---|---|
| **Дефектоскопист / NDT** (Non-destructive testing) | **Planned** | Used across welding, oil & gas, aviation, nuclear; laddered certification | ISO 9712, ASNT, Ростехнадзор; UT/RT/MT/PT |
| **Оператор ЧПУ** (CNC machinist) | **Live** (`operator-cnc`) | Manufacturing reshoring; thin pipeline | G-code, GD&T, metrology, materials |
| **Промышленный механик / наладчик** (Millwright / maintenance) | **Planned** | Keeps plants running; aging workforce | Hydraulics, pneumatics, alignment, vibration |
| **Релейная защита / подстанции** (Power systems / protection) | **Planned** | Grid expansion + energy transition | ПУЭ, ПТЭЭП, РЗА, substation practice |
| **Схемотехник / разработчик электроники** (PCB & embedded hardware) | **Planned** | Hardware-talent gap; import-substitution push | ЕСКД (УГО), IPC-2221/7351, EMC — *standards-rich but not a licensed trade; KiCad makes practice cheap* |
| **Инженер по обращению с отходами** (Waste-management / recycling tech) | **Planned** | Waste reform + EPR (РОП); real deficit | ФЗ-89, СанПиН, ГОСТ on отходы; sorting-line automation touches our АСУ ТП moat |

## Tier 4 — civil infrastructure & construction (huge deficit, expert-gated)

Aging roads, bridges, water mains and district-heating networks are a global,
structural problem, and the work is heavily standardized (СП / СНиП / ГОСТ) —
which fits our format well. Two cautions shape how we package it:

- **"Construction" is a domain, not a profession.** Don't build one shallow
  «Строительство» path — that breaks the depth rule. Decompose into specific deep
  trades, each its own Path, the way «Электрик» is one structured path and not
  "all electrical work".
- **This whole tier is author-gated.** The founder's depth is OT, not asphalt or
  concrete — so it's prime "wanted board" material for co-authors (VISION's
  expert-driven expansion), not solo founder work.

The two standout layers — both a near-perfect format fit:
- **Inspection / lab-QC roles** — like NDT, test-and-standard heavy.
- **The engineers who live inside the codes** — design, estimating, surveying:
  their *entire job* is applying a body of official documents, which is exactly
  our read-the-standard format (these fit better than the manual trades, even
  though the trades have the louder labour shortage).

| Profession | Deficit driver | Depth anchor |
|---|---|---|
| **Инженер-конструктор (ПГС)** (Structural design — RC/steel) | Licensed design shortage; deepest code body | СП on нагрузки/бетон/металл, Eurocodes; ГИП ladder |
| **Сметчик** (Construction cost estimator) | Highly regulated method; chronic demand | ГЭСН/ФЕР/ТЕР; estimating software — *the most standardized desk role* |
| **Геодезист** (Surveyor) | Underpins roads + construction | СП on геодезические работы; total station, GNSS |
| **BIM / ТИМ-специалист** (BIM modeller) | Newly mandated (ТИМ); modern + deep | ТИМ постановления; IFC, native modellers |
| **Дорожник + лабораторный контроль** (Road construction & QC lab) | Aging roads everywhere; thin QC pipeline | СП 78.13330; ГОСТ on асфальтобетон/грунты; укладка, уплотнение, lab testing |
| **Эксплуатация инженерных сетей ЖКХ** (Municipal water / heat / sewer networks) | Aging municipal infrastructure | СП/СНиП on водоснабжение и теплосети; pumps & pumping stations; diagnostics, repair |
| **Оператор котельной / теплотехник** (Boiler & heat-plant operation) | Every город heats with котельные; aging operators, Ростехнадзор-licensed | ФНП ОРПД, ПТЭ тепловых энергоустановок, СП 89.13330; водоподготовка, безопасность под давлением |
| **Стройконтроль / технадзор** (Construction QC / technical supervision) | Quality enforcement scarce | СП; входной/операционный контроль; исполнительная документация |
| **Бетонные и монолитные работы** (Concrete & rebar / formwork) | Core of every build; skilled shortage | ГОСТ on бетон/арматуру; опалубка; технология бетонирования |
| **Обследование зданий и сооружений** (Structural inspection, incl. bridges) | Safety of aging structures; overlaps NDT | ГОСТ 31937; СП on обследование; defectoscopy methods |

## Horizon — energy transition, data & food economy (future-fit)

Strong, growing deficits with a clear hands-on core — good candidates once Tiers
1–2 are solid, or sooner if an expert steps up.

- **Техник ветрогенераторов** (Wind turbine technician) — among the
  fastest-growing occupations; deep, safety-critical (GWO-style training).
- **Техник дата-центров / critical facilities** — explosive AI/cloud demand;
  power + cooling + UPS, very current.
- **Монтажник солнечных систем** (Solar PV installer) — booming; electrical +
  structural + code.
- **Рыбовод / аквакультура — УЗВ/RAS** (Recirculating aquaculture systems) — food
  security + declining wild catch. The sleeper fit: a modern fish farm in
  artificial conditions is a **controlled process plant** (water chemistry, pumps,
  biofilters, sensors, automation) — it rides our АСУ ТП / КИПиА moat far more
  than it resembles traditional farming. Prefer it over generic agriculture.

## Wide ceiling — beyond industrial (per VISION)

Only when a real practitioner co-authors it — this is the "any complex modern
profession" vision, voiced on `/contribute`, not founder-driven breadth.

- **Агроном / точное земледелие** (Agronomist / precision agriculture) — food
  security; the canonical wide-ceiling example. Precision-ag (sensors, GNSS,
  drones, GIS) is the most "industrial" slice and the easiest to package.
- **Механизатор** (Agricultural machinery operator) — the practical twin of the
  agronomist and the easier of the two to package: tractors, combines, seeding and
  tillage rigs — setup, regulation, fault-finding, GNSS guidance and section
  control. Machinery is documented (manuals, regulation charts) where biology is
  tacit, so the standards-spine problem below largely doesn't apply. Note the
  scope: this is the **operator-mechanic trade**, not «фермер» — a farmer is a
  business role that decomposes into this, the agronomist and the zootechnician,
  and would enter as one shallow path (the rule at the top of this file).
- **Зоотехник / животновод** (Livestock specialist) — deep and in demand, but two
  honest caveats: agriculture is **less standards-driven** than the trades (more
  tacit, condition-dependent biology than read-the-ГОСТ), and **cheap, safe
  practice is harder to design** (land and animals, not a bench). Genuinely
  co-author-gated — the founder can't fake depth here; add it when a practitioner
  brings both the knowledge *and* a workable practice design.
- **Фотограф-видеограф** (Photographer / videographer) — **Live** (`fotograf-videograf`).
  The list's first non-industrial entry, added deliberately. It clears depth (optics,
  sensor physics, colorimetry, exposure) and has a real standards spine — ISO 12232 /
  12233, ITU-R BT.709 / BT.1886 / BT.2100, CIE 015, EBU R 128 and Tech 3355 — plus
  documented best practice (ASC Manual, Hunter/Biver/Fuqua, Adams, Block) where no
  standard exists. Practice is near-free: measurements of one's own camera and lens,
  ephemeris-planned light, deliberate constraint exercises. **The honest caveat:** it
  is a creative-services trade, not a hands-on industrial one, so it stretches the
  wedge further than anything else here. It earns the slot only because the path is
  built around the *measurable and sourceable* half — physics, protocol, verifiable
  practice — and explicitly refuses the taste-and-vibes framing.
  **Positioned as a pursuit, not a trade** (founder, 2026-08-23): the landing frames it
  as rest, a family archive and a specialist's publicity tool (shooting your own work
  and products well) — no career promise; the craft curriculum itself is unchanged.
- **Градостроитель / урбанист** (Urban planner) — a real regulated design
  profession (СП 42.13330, master/transport planning, zoning) with genuine depth,
  and a topic the founder cares about. **The honest caveat — this is the list's
  most likely identity-bender:** packaged as the *planning profession* it's
  on-filter; packaged as "why Swiss/Dutch cities feel good" civic philosophy it
  drifts off it — those are values and judgment, not documents you read to
  qualify, and verifiable hands-on practice is the open problem. Build it as the
  profession, with the Swiss/Dutch "why" living as the motivating WHY *inside*
  lessons — not as a standalone explainer for mayors.

## Deliberately not adding (fails a criterion)

- **Heavily proctored / region-locked licences** where reading the standard
  genuinely can't make you competent (e.g. aircraft maintenance, marine
  engineer). They're deep and in demand, but the certification is gatekept and
  region-specific — near-term self-serve fit is low. We can still teach the
  *knowledge*, but be honest about what it attests (same rule as certificates).
- **Shallow trades** with no apprentice→expert ladder — they're a course inside a
  profession, not a profession.
- **Pure-theory / desk roles** with no verifiable hands-on practice — they fail
  the spirit-fit test.
- **Anything whose practice needs unsafe or expensive setups** we can't reduce to
  a cheap, safe bench version — it fails packageability.
- **Public-awareness / general-explainer content** ("why sort your trash", "why
  cities should be walkable") — important, but it's civic education aimed at the
  public, not a deep regulated vocation: no read-the-standard spine, no
  apprentice→expert ladder, no verifiable practice. The *professional* version
  belongs (waste-management engineer, urban planner) and the awareness lives as
  WHY-context inside it — the standalone campaign does not.

## How to use this list

- Pick the next profession from the **highest tier with a ready author** (you, or
  a co-author). Within a tier, prefer the one with the clearest standard set and
  the cheapest safe practice.
- Update **Status** as content lands; promote/demote freely as demand signals
  arrive. This file is meant to churn — that's its job.
- A curated public excerpt lives on `/contribute` as the "wanted professions"
  board (`ru.yml → contribute.wanted`) — refresh it when tiers churn.
</content>
