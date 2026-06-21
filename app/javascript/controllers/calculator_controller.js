import { Controller } from "@hotwired/stimulus"

// One controller for every calculator on /calculators. A calculator form
// declares its formula via data-calculator-formula-value="ohmsLaw"; on each
// input the controller gathers the fields (data-field="u" → numbers, <select>
// → strings), calls the matching method below, and writes the returned strings
// into the output slots (data-output="i"). It's plain physics/standards math,
// kept together in one auditable file on purpose.
//
// Safety note: the numbers are estimates. The forms carry the normative source
// and the "сверяйтесь с проектом" disclaimer — this controller only does the
// arithmetic. Reference tables/constants are cited next to their formula.
export default class extends Controller {
  static values = { formula: String }

  connect() {
    this.compute()
  }

  // data-action on the root re-runs on every input/change inside the form.
  compute() {
    const fn = this[this.formulaValue]
    if (typeof fn !== "function") return
    this.render(fn.call(this, this.read()) || {})
  }

  // Gather every labelled control: <select> → string, input with `data-text`
  // → trimmed string (e.g. an IP address), numeric <input> → Number,
  // blank/garbage → null (lets formulas test `x == null`).
  read() {
    const data = {}
    this.element.querySelectorAll("[data-field]").forEach((el) => {
      if (el.tagName === "SELECT" || el.dataset.text != null) {
        data[el.dataset.field] = el.tagName === "SELECT" ? el.value : (el.value || "").trim()
      } else {
        const n = parseFloat((el.value || "").replace(",", "."))
        data[el.dataset.field] = Number.isFinite(n) ? n : null
      }
    })
    return data
  }

  // A formula returns either a plain string per output slot, or an object
  // { text, status } — `status` ("ok"/"warn"/"") drives a verdict colour on the
  // slot and its enclosing result row (green within norm / red over it).
  render(out) {
    for (const [key, value] of Object.entries(out)) {
      const text = value && typeof value === "object" ? value.text : value
      const status = value && typeof value === "object" ? value.status : null
      this.element.querySelectorAll(`[data-output="${key}"]`).forEach((el) => {
        el.textContent = text
        if (status != null) {
          el.dataset.status = status
          const row = el.closest(".calc-result")
          if (row) row.dataset.status = status
        }
      })
    }
  }

  // Copy a headline result to the clipboard — the one thing you want from a
  // calculator mid-job. Button sits next to the value; flips to a check briefly.
  copy(event) {
    const btn = event.currentTarget
    const el = btn.parentElement.querySelector("[data-output]")
    const text = el?.textContent?.trim()
    if (!text || text === "—" || !navigator.clipboard) return
    navigator.clipboard.writeText(text).then(() => {
      btn.classList.add("calc-copy--done")
      clearTimeout(this.copyTimer)
      this.copyTimer = setTimeout(() => btn.classList.remove("calc-copy--done"), 1200)
    })
  }

  // ── number formatting (ru-RU: comma decimal, thin-space thousands) ──
  num(value, digits = 2) {
    if (value == null || !Number.isFinite(value)) return "—"
    return value.toLocaleString("ru-RU", { maximumFractionDigits: digits })
  }

  // Significant-digit form for converters, where values span many orders of
  // magnitude (1 МПа = 0,000145 psi … = 10 197 мм вод. ст.).
  sig(value, digits = 5) {
    if (value == null || !Number.isFinite(value)) return "—"
    return value.toLocaleString("ru-RU", { maximumSignificantDigits: digits })
  }

  // ── Электрик ─────────────────────────────────────────────────────────

  // Ohm's-law "wheel": enter any two of U, I, R, P → the rest. Three passes
  // let a value derived in one pass feed the next.
  ohmsLaw(v) {
    let { u, i, r, p } = v
    for (let pass = 0; pass < 3; pass++) {
      if (u == null && i != null && r != null) u = i * r
      if (u == null && p != null && i != null && i !== 0) u = p / i
      if (u == null && p != null && r != null && p * r >= 0) u = Math.sqrt(p * r)
      if (i == null && u != null && r != null && r !== 0) i = u / r
      if (i == null && p != null && u != null && u !== 0) i = p / u
      if (i == null && p != null && r != null && r > 0) i = Math.sqrt(p / r)
      if (r == null && u != null && i != null && i !== 0) r = u / i
      if (r == null && u != null && p != null && p !== 0) r = (u * u) / p
      if (r == null && p != null && i != null && i !== 0) r = p / (i * i)
      if (p == null && u != null && i != null) p = u * i
      if (p == null && i != null && r != null) p = i * i * r
      if (p == null && u != null && r != null && r !== 0) p = (u * u) / r
    }
    return { u: this.num(u, 3), i: this.num(i, 3), r: this.num(r, 3), p: this.num(p, 3) }
  }

  // Ток по мощности. 1-ф: I = P / (U·cosφ); 3-ф: I = P / (√3·U·cosφ).
  powerCurrent(v) {
    const u = v.u
    const cos = v.cos ?? 0.95
    const pW = v.p != null ? v.p * 1000 : null // кВт → Вт
    if (pW == null || u == null || u === 0 || !cos) return { i: "—", s: "—" }
    const denom = v.phase === "1" ? u * cos : Math.sqrt(3) * u * cos
    return { i: this.num(pW / denom, 1), s: this.num(pW / cos / 1000, 2) }
  }

  // Падение напряжения в линии (активное сопротивление жилы; реактивным
  // пренебрегаем — допустимо для сечений примерно до 50–95 мм²). L — длина
  // линии в одну сторону. 1-ф: ΔU = 2·ρ·L·I/S; 3-ф: ΔU = √3·ρ·L·I/S.
  // ρ (Ом·мм²/м): медь 0,0175, алюминий 0,0294.
  voltageDrop(v) {
    const rho = v.material === "al" ? 0.0294 : 0.0175
    const k = v.phase === "1" ? 2 : Math.sqrt(3)
    const { l, i, s, u } = v
    if (l == null || i == null || s == null || s === 0) {
      return { du: "—", dupct: { text: "—", status: "" } }
    }
    const du = (k * rho * l * i) / s
    const pct = u ? (du / u) * 100 : null
    // ПУЭ/ГОСТ норма для силовых и осветительных сетей — обычно ≤ 5 %.
    const status = pct == null ? "" : pct <= 5 ? "ok" : "warn"
    return { du: this.num(du, 2), dupct: { text: this.num(pct, 2), status } }
  }

  // Подбор сечения по длительно допустимому току (ПУЭ-7, таблицы 1.3.4/1.3.6 —
  // медь, 1.3.7/1.3.8 — алюминий; провода/кабели с ПВХ/резиновой изоляцией).
  // Базовый расчёт без поправочных коэффициентов (температура, группировка) —
  // отсюда дисклеймер в форме. Берём наименьшее стандартное сечение, чей
  // допустимый ток ≥ расчётного.
  cableCrossSection(v) {
    const TABLES = {
      cu: {
        air: [[1.5, 23], [2.5, 30], [4, 41], [6, 50], [10, 80], [16, 100], [25, 140], [35, 170], [50, 215], [70, 270], [95, 330], [120, 385]],
        pipe: [[1.5, 19], [2.5, 27], [4, 38], [6, 46], [10, 70], [16, 85], [25, 115], [35, 135], [50, 185], [70, 225], [95, 275], [120, 315]]
      },
      al: {
        air: [[2.5, 24], [4, 32], [6, 39], [10, 60], [16, 75], [25, 105], [35, 130], [50, 165], [70, 210], [95, 255], [120, 295]],
        pipe: [[2.5, 20], [4, 28], [6, 36], [10, 50], [16, 60], [25, 85], [35, 100], [50, 140], [70, 175], [95, 215], [120, 245]]
      }
    }
    const u = v.u ?? (v.phase === "1" ? 220 : 380)
    const cos = v.cos ?? 0.95
    let current = v.i
    if (current == null && v.p != null) {
      const denom = v.phase === "1" ? u * cos : Math.sqrt(3) * u * cos
      current = denom ? (v.p * 1000) / denom : null
    }
    if (current == null) return { current: "—", section: "—", allowed: "—", breaker: "—" }
    const table = (TABLES[v.material] || TABLES.cu)[v.laying === "pipe" ? "pipe" : "air"]
    const pick = table.find(([, amps]) => amps >= current)
    // Рекомендуемый автомат: стандартный номинал (ГОСТ Р 50345/IEC 60898), который
    // защищает кабель (Iₙ ≤ Iдоп) и пропускает рабочий ток (Iₙ ≥ Iрасч) — берём
    // наибольший подходящий из ряда. Окончательный выбор — с учётом селективности.
    const RATINGS = [6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125]
    const breaker = pick ? RATINGS.filter((r) => r >= current && r <= pick[1]).pop() : null
    return {
      current: this.num(current, 1),
      section: pick ? this.num(pick[0], 1) : "> 120",
      allowed: pick ? this.num(pick[1], 0) : "—",
      breaker: breaker ? this.num(breaker, 0) : "—"
    }
  }

  // Сопротивление заземляющего устройства из вертикальных электродов.
  // Одиночный электрод (стержень у поверхности): R₁ = ρ/(2π·L)·[ln(2L/d) +
  // 0,5·ln((4t+L)/(4t−L))], t = h + L/2 — глубина до середины электрода.
  // ρ берётся расчётным: ρ·ψ (ψ — сезонный/климатический коэффициент).
  // Группа из n электродов с коэффициентом использования η: Rгр = R₁/(n·η).
  // Норма обычно 4 Ом (ПУЭ 1.7) — отсюда требуемое число электродов.
  grounding(v) {
    const rho = (v.rho ?? 100) * (v.psi ?? 1.5)
    const L = v.l ?? 3
    const d = (v.d ?? 16) / 1000 // мм → м
    const h = v.h ?? 0.7
    const n = Math.max(1, Math.round(v.n ?? 1))
    const eta = v.eta != null && v.eta > 0 ? v.eta : 1
    const target = v.target != null && v.target > 0 ? v.target : 4
    if (L <= 0 || d <= 0 || rho <= 0) return { r1: "—", rgroup: "—", nreq: "—" }
    const t = h + L / 2
    const r1 = (rho / (2 * Math.PI * L)) * (Math.log((2 * L) / d) + 0.5 * Math.log((4 * t + L) / (4 * t - L)))
    const rgroup = r1 / (n * eta)
    const nreq = Math.ceil(r1 / (target * eta))
    return { r1: this.num(r1, 2), rgroup: this.num(rgroup, 2), nreq: this.num(nreq, 0) }
  }

  // Ток однофазного КЗ петли «фаза-нуль» (ГОСТ 28249). Iₖ = Uф/(Zвнеш + Zп),
  // Zп ≈ 2·ρ·L/S (фаза + нуль той же длины/сечения, реактивным пренебрегаем).
  // Zвнеш — сопротивление до щита (трансформатор + магистраль) задаёт сам
  // пользователь (или измеренное Z петли), чтобы не зашивать неточные таблицы.
  // Проверка автомата: для ГАРАНТИРОВАННОГО мгновенного отключения берём верхнюю
  // границу полосы расцепления Iₖ ≥ k·Iₙ (k: B=5, C=10, D=20 по ГОСТ IEC 60898) —
  // консервативно, в пользу безопасности; отсюда цвет кратности.
  shortCircuit(v) {
    const uf = v.uf ?? 220
    const zext = v.zext ?? 0
    const rho = v.material === "al" ? 0.0294 : 0.0175
    const { l, s } = v
    if (l == null || s == null || s <= 0) return { zloop: "—", ikz: "—", ratio: { text: "—", status: "" } }
    const rloop = (2 * rho * l) / s
    const zloop = zext + rloop
    const ikz = uf / zloop
    const k = { B: 5, C: 10, D: 20 }[v.char] || 10
    let ratio = { text: "—", status: "" }
    if (v.inom != null && v.inom > 0) {
      const r = ikz / v.inom
      ratio = { text: this.num(r, 1), status: r >= k ? "ok" : "warn" }
    }
    return { zloop: this.num(zloop, 3), ikz: this.num(ikz, 0), ratio }
  }

  // Ток утечки и выбор уставки УЗО (ПУЭ 7.1.83). Расчётный ток утечки: 0,4 мА
  // на 1 А тока нагрузки (естественная утечка ЭП) + 0,01 мА на 1 м фазного
  // проводника. Рабочий ток утечки должен быть ≤ 1/3 номинала УЗО — иначе
  // ложные срабатывания; отсюда цвет. (Уставка 30 мА — защита человека.)
  rcd(v) {
    const setting = parseFloat(v.setting) || 30 // мА
    const { i, l } = v
    if (i == null && l == null) return { ileak: { text: "—", status: "" }, threshold: "—" }
    const ileak = 0.4 * (i ?? 0) + 0.01 * (l ?? 0)
    const threshold = setting / 3
    return {
      ileak: { text: this.num(ileak, 2), status: ileak <= threshold ? "ok" : "warn" },
      threshold: this.num(threshold, 2)
    }
  }

  // ── КИПиА ────────────────────────────────────────────────────────────

  // Масштабирование токовой петли ↔ инженерные единицы (линейно). Диапазон
  // сигнала по умолчанию 4–20 мА. Считает обе стороны сразу: ток → величина (+%)
  // и величина → ток, по одному диапазону.
  maScaling(v) {
    const lo = v.rmin
    const hi = v.rmax
    const smin = v.smin ?? 4
    const smax = v.smax ?? 20
    const span = smax - smin
    const euSpan = lo != null && hi != null ? hi - lo : null

    let eu = "—"
    let percent = "—"
    if (v.ma != null && euSpan != null && span) {
      const frac = (v.ma - smin) / span
      eu = this.num(lo + frac * euSpan, 4)
      percent = this.num(frac * 100, 1)
    }

    let ma = "—"
    if (v.eu != null && euSpan) {
      ma = this.num(smin + ((v.eu - lo) / euSpan) * span, 3)
    }

    return { eu, percent, ma }
  }

  // Термосопротивление (ТСМ/ТСП/Pt) ↔ температура по ГОСТ 6651-2009. Прямой
  // ход t→R через уравнение Каллендара–Ван Дюзена; обратный R→t — делением
  // отрезка (W монотонна по t), без таблиц обратных коэффициентов. Платина
  // (α 0,00385 — Pt, 0,00391 — П) и медь (α 0,00428 — М) с разными ветвями
  // ниже и выше 0 °C. Считает обе стороны сразу по выбранному типу датчика.
  resistanceThermometer(v) {
    const TYPES = {
      pt100: { r0: 100, mat: "pt" }, pt500: { r0: 500, mat: "pt" }, pt1000: { r0: 1000, mat: "pt" },
      "100p": { r0: 100, mat: "p" }, "50p": { r0: 50, mat: "p" },
      "100m": { r0: 100, mat: "m" }, "50m": { r0: 50, mat: "m" }
    }
    const ty = TYPES[v.type] || TYPES.pt100
    const r0 = ty.r0
    const PT = { A: 3.9083e-3, B: -5.775e-7, C: -4.183e-12 }
    const P = { A: 3.9692e-3, B: -5.829e-7, C: -4.3303e-12 }
    // W(t) = Rt/R0 — отношение сопротивлений
    const W = (temp) => {
      if (ty.mat === "m") {
        const A = 4.28e-3
        if (temp >= 0) return 1 + A * temp
        return 1 + A * temp - 6.2032e-7 * temp * (temp + 6.7) + 8.5154e-10 * temp ** 3
      }
      const c = ty.mat === "p" ? P : PT
      if (temp >= 0) return 1 + c.A * temp + c.B * temp * temp
      return 1 + c.A * temp + c.B * temp * temp + c.C * (temp - 100) * temp ** 3
    }
    const range = ty.mat === "m" ? [-180, 200] : [-200, 850]

    let rOut = "—"
    if (v.t != null && v.t >= range[0] && v.t <= range[1]) rOut = this.num(r0 * W(v.t), 3)

    let tOut = "—"
    if (v.r != null && v.r > 0) {
      const target = v.r / r0
      if (target > W(range[0]) && target < W(range[1])) {
        let lo = range[0], hi = range[1]
        for (let k = 0; k < 60; k++) {
          const mid = (lo + hi) / 2
          if (W(mid) < target) lo = mid
          else hi = mid
        }
        tOut = this.num((lo + hi) / 2, 2)
      }
    }
    return { rOut, tOut }
  }

  // Погрешность измерения и поверка по классу точности (ГОСТ 8.401). Абсолютная
  // Δ = изм − действ; относительная δ = Δ/действ·100 %; приведённая γ = Δ/Xн·100 %
  // (Xн — нормирующее значение, обычно верхний предел диапазона). Прибор годен,
  // если |γ| ≤ класса точности — отсюда цвет приведённой погрешности.
  measurementError(v) {
    const { measured, actual, span, cls } = v
    if (measured == null || actual == null) {
      return { abs: "—", rel: "—", red: { text: "—", status: "" }, limit: "—" }
    }
    const abs = measured - actual
    const rel = actual !== 0 ? (abs / actual) * 100 : null
    const red = span != null && span !== 0 ? (abs / span) * 100 : null
    let redOut = { text: this.num(red, 3), status: "" }
    let limit = "—"
    if (cls != null && red != null) {
      limit = "± " + this.num(cls, 2)
      redOut = { text: this.num(red, 3), status: Math.abs(red) <= cls ? "ok" : "warn" }
    }
    return { abs: this.num(abs, 4), rel: this.num(rel, 3), red: redOut, limit }
  }

  // Пропускная способность Kv регулирующего клапана для жидкости (ГОСТ 23866 /
  // IEC 60534, турбулентный режим): Kv = Q·√(ρотн/ΔP), ρотн = ρ/1000 (вода = 1),
  // Q в м³/ч, ΔP в бар. Слева — подбор Kv по расходу; справа — проверка: какой
  // расход даст выбранный Kvs при том же перепаде. Запас Kvs ≈ +20…30 % к Kv.
  valveKv(v) {
    const dp = v.dp
    const rhoRel = (v.rho ?? 1000) / 1000
    const ok = dp != null && dp > 0 && rhoRel > 0
    let kvReq = "—"
    if (ok && v.q != null) kvReq = this.num(v.q * Math.sqrt(rhoRel / dp), 3)
    let qMax = "—"
    if (ok && v.kvs != null) qMax = this.num(v.kvs * Math.sqrt(dp / rhoRel), 3)
    return { kvReq, qMax }
  }

  // Давление: всё через Паскали. Множители — значения единицы в Па.
  pressure(v) {
    const TO_PA = {
      pa: 1, kpa: 1e3, mpa: 1e6, bar: 1e5,
      kgf: 98066.5, atm: 101325, psi: 6894.757, mmhg: 133.322, mmh2o: 9.80665
    }
    const keys = Object.keys(TO_PA)
    if (v.value == null) return Object.fromEntries(keys.map((k) => [k, "—"]))
    const pa = v.value * TO_PA[v.unit || "bar"]
    return Object.fromEntries(keys.map((k) => [k, this.sig(pa / TO_PA[k])]))
  }

  // ── Сетевому инженеру ────────────────────────────────────────────────

  // Линия витой пары с питанием PoE: падение напряжения и запас по длине.
  // R жилы (Ом/м, медь 20 °C) — по сечению (AWG). PoE 2 пары (802.3af/at):
  // шлейф = Rж·L; 4 пары (802.3bt): жилы параллелятся → шлейф = Rж·L/2.
  // ΔU = I·Rшлейфа; U на устройстве = Uисточника − ΔU (должно быть ≥ Umin PD).
  // Длина данных в любом случае ограничена 100 м (ISO/IEC 11801).
  twistedPairLine(v) {
    const AWG = { 26: 0.1345, 24: 0.0842, 23: 0.0668, 22: 0.053 }
    const rc = AWG[v.awg] || AWG[24]
    const L = v.l ?? 50
    const STD = {
      af: { pairs: 2, i: 0.35, vpse: 48, pdmin: 37 },
      at: { pairs: 2, i: 0.6, vpse: 50, pdmin: 42.5 },
      bt3: { pairs: 4, i: 0.6, vpse: 50, pdmin: 42.5 },
      bt4: { pairs: 4, i: 0.96, vpse: 52, pdmin: 41.1 }
    }
    const s = STD[v.std] || STD.at
    const i = v.i ?? s.i
    const vpse = v.vpse ?? s.vpse
    if (L < 0 || i <= 0) return { rloop: "—", vdrop: "—", vpd: { text: "—", status: "" }, lmax: "—" }
    const rloop = s.pairs === 2 ? rc * L : (rc * L) / 2
    const vdrop = i * rloop
    const vpd = vpse - vdrop
    // Предельная длина, пока U на устройстве ещё ≥ Umin (и не больше 100 м СКС).
    const rloopMax = (vpse - s.pdmin) / i
    const lmax = s.pairs === 2 ? rloopMax / rc : (rloopMax * 2) / rc
    return {
      rloop: this.num(rloop, 2),
      vdrop: this.num(vdrop, 2),
      vpd: { text: this.num(vpd, 1), status: vpd >= s.pdmin ? "ok" : "warn" },
      lmax: this.num(Math.max(0, Math.min(lmax, 100)), 0)
    }
  }

  // Калькулятор подсетей IPv4: адрес + префикс CIDR → маска, адрес сети,
  // широковещательный, диапазон хостов, их число, wildcard. Чистая битовая
  // арифметика (>>> 0 — беззнаковые 32-бит). /31 и /32 — особые случаи (RFC 3021).
  subnet(v) {
    const out = { network: "—", mask: "—", wildcard: "—", broadcast: "—", hostmin: "—", hostmax: "—", hosts: "—" }
    const m = (v.ip || "").match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
    if (!m || v.prefix == null || v.prefix < 0 || v.prefix > 32) return out
    const oct = m.slice(1, 5).map(Number)
    if (oct.some((o) => o > 255)) return out
    const p = Math.floor(v.prefix)
    const toIp = (n) => [(n >>> 24) & 255, (n >>> 16) & 255, (n >>> 8) & 255, n & 255].join(".")
    const ip = ((oct[0] << 24) | (oct[1] << 16) | (oct[2] << 8) | oct[3]) >>> 0
    const mask = p === 0 ? 0 : (0xffffffff << (32 - p)) >>> 0
    const net = (ip & mask) >>> 0
    const bcast = (net | (~mask >>> 0)) >>> 0
    let hosts, hostmin, hostmax
    if (p >= 31) {
      hosts = p === 32 ? 1 : 2
      hostmin = toIp(net)
      hostmax = toIp(bcast)
    } else {
      hosts = Math.pow(2, 32 - p) - 2
      hostmin = toIp((net + 1) >>> 0)
      hostmax = toIp((bcast - 1) >>> 0)
    }
    return {
      network: toIp(net) + "/" + p,
      mask: toIp(mask),
      wildcard: toIp(~mask >>> 0),
      broadcast: toIp(bcast),
      hostmin,
      hostmax,
      hosts: this.num(hosts, 0)
    }
  }

  // Время опроса Modbus RTU (чтение N регистров, FC03). Кадр запроса — 8 байт,
  // ответа — 5 + 2·N байт. Время байта = бит/байт ÷ скорость; межкадровая пауза
  // t3.5 = 3,5 символа (по 11 бит) при ≤ 19200 бод и фиксированные 1,75 мс выше.
  // Транзакция = (запрос+ответ)·tбайт + 2·t3.5 + задержка ответа slave.
  modbusRtu(v) {
    const baud = parseFloat(v.baud) || 9600
    const bpc = parseFloat(v.bpc) || 11
    const n = Math.max(0, Math.round(v.n ?? 10))
    const dev = Math.max(1, Math.round(v.dev ?? 1))
    const slaveS = (v.delay ?? 0) / 1000
    if (baud <= 0) return { respbytes: "—", ttrans: "—", rate: "—", tcycle: "—" }
    const reqBytes = 8
    const respBytes = 5 + 2 * n
    const tChar = bpc / baud
    const t35 = baud > 19200 ? 0.00175 : (3.5 * 11) / baud
    const tTrans = (reqBytes + respBytes) * tChar + 2 * t35 + slaveS
    return {
      respbytes: this.num(respBytes, 0),
      ttrans: this.num(tTrans * 1000, 1),
      rate: this.num(tTrans > 0 ? 1 / tTrans : null, 0),
      tcycle: this.num(tTrans * dev * 1000, 1)
    }
  }
}
