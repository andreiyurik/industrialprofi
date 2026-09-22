import { Controller } from "@hotwired/stimulus"
import { parseNumber, formatNumber, formatSignificant } from "calculators/format"

// Runs formula-only calculators directly and serves as the base class for
// controllers/calculators/* that also draw a diagram; accuracy disclaimers live in the form.
export default class extends Controller {
  // norms comes from the server so the page's own table and the formula share one copy.
  static values = { formula: String, norms: Object }

  connect() {
    this.compute()
  }

  // data-action on the root re-runs on every input/change inside the form.
  compute(event) {
    this.#mirrorRange(event?.target)
    this.#applyPreset(event?.target)
    this.paint(this.read())
  }

  // Override to also draw a diagram; everything else in the base class stays untouched.
  paint(input) {
    const fn = this[this.formulaValue]
    if (typeof fn !== "function") return
    this.render(fn.call(this, input) || {})
  }

  // Blank/garbage input becomes null, so formulas can test `x == null`.
  read() {
    const data = {}
    this.element.querySelectorAll("[data-field]").forEach((el) => {
      if (el.tagName === "SELECT" || el.dataset.text != null) {
        data[el.dataset.field] = el.tagName === "SELECT" ? el.value : (el.value || "").trim()
      } else {
        data[el.dataset.field] = parseNumber(el.value)
      }
    })
    this.#followRanges(data)
    this.#followPresets(data)
    return data
  }

  // A formula returns a string, or { text, status } where status drives the result
  // row's colour. The reserved `verdict` key has no output slot of its own.
  render(out) {
    for (const [key, value] of Object.entries(out)) {
      const text = value && typeof value === "object" ? value.text : value
      const status = value && typeof value === "object" ? value.status : null
      this.element.querySelectorAll(`[data-output="${key}"]`).forEach((el) => {
        el.textContent = text
        if (status != null) {
          el.dataset.status = status
          const row = el.closest(".calc-result, .calc-answer")
          if (row) row.dataset.status = status
        }
      })
    }
    this.#renderVerdict(out.verdict)
  }

  // Diagram labels — like [data-output] but without status; the diagram's colour
  // is set elsewhere, for the picture as a whole.
  label(figures) {
    for (const [key, text] of Object.entries(figures)) {
      const slot = this.element.querySelector(`[data-figure="${key}"]`)
      if (slot) slot.textContent = text
    }
  }

  // Bound on the panel, not each button: the target differs per calculator, so a
  // data-action spelled into the partial couldn't resolve generically.
  copy(event) {
    const btn = event.target.closest(".calc-copy")
    if (!btn) return

    const el = btn.parentElement.querySelector("[data-output]")
    const text = el?.textContent?.trim()
    if (!text || text === "—" || !navigator.clipboard) return
    navigator.clipboard.writeText(text).then(() => {
      btn.classList.add("calc-copy--done")
      clearTimeout(this.copyTimer)
      this.copyTimer = setTimeout(() => btn.classList.remove("calc-copy--done"), 1200)
    })
  }

  // locale comes from <html lang>
  num(value, digits = 2) {
    return formatNumber(value, digits)
  }

  sig(value, digits = 5) {
    return formatSignificant(value, digits)
  }

  // Only the number input carries data-field, so read() never sees two values for one slider.
  #mirrorRange(target) {
    const field = target?.dataset?.rangeFor
    if (!field) return
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = target.value
  }

  // Phrasings come from the locale via data attributes — never hardcode Russian here.
  #renderVerdict(status) {
    const el = this.element.querySelector("[data-verdict]")
    if (!el) return

    const state = status || ""
    el.dataset.status = state
    el.querySelector("[data-verdict-text]").textContent =
      state === "ok" ? el.dataset.verdictOk : state === "warn" ? el.dataset.verdictWarn : el.dataset.verdictIdle
  }

  #followRanges(data) {
    this.element.querySelectorAll("[data-range-for]").forEach((range) => {
      const value = data[range.dataset.rangeFor]
      if (value != null) range.value = String(value)
    })
  }

  // Like a slider, a preset is a helper, not a field — it never reaches read().
  #applyPreset(target) {
    const field = target?.dataset?.presetFor
    if (!field || !target.value) return
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = target.value
  }

  // Falls back to the "custom value" option once the number stops matching the preset.
  #followPresets(data) {
    this.element.querySelectorAll("[data-preset-for]").forEach((select) => {
      const value = data[select.dataset.presetFor]
      const match = [ ...select.options ].find((option) => option.value !== "" && Number(option.value) === value)
      select.value = match ? match.value : ""
    })
  }

  // ── Электрик ─────────────────────────────────────────────────────────

  // Ток утечки и уставка УЗО — ПУЭ 7.1.83.
  rcd(v) {
    const setting = parseFloat(v.setting) || 30 // мА
    const { i, l } = v
    if (i == null && l == null) return { ileak: { text: "—", status: "" }, threshold: "—", verdict: null }
    const ileak = 0.4 * (i ?? 0) + 0.01 * (l ?? 0)
    const threshold = setting / 3
    const status = ileak <= threshold ? "ok" : "warn"
    return {
      ileak: { text: this.num(ileak, 2), status },
      threshold: this.num(threshold, 2),
      verdict: status
    }
  }

  // Ток КЗ петли «фаза-нуль» — ГОСТ 28249; проверка автомата — ГОСТ IEC 60898.
  shortCircuit(v) {
    const uf = v.uf ?? 220
    const zext = v.zext ?? 0
    const rho = v.material === "al" ? 0.0294 : 0.0175
    const { l, s } = v
    if (l == null || s == null || s <= 0) return { zloop: "—", ikz: "—", ratio: { text: "—", status: "" }, verdict: null }
    const rloop = (2 * rho * l) / s
    const zloop = zext + rloop
    const ikz = uf / zloop
    const k = { B: 5, C: 10, D: 20 }[v.char] || 10
    let ratio = { text: "—", status: "" }
    if (v.inom != null && v.inom > 0) {
      const r = ikz / v.inom
      ratio = { text: this.num(r, 1), status: r >= k ? "ok" : "warn" }
    }
    return { zloop: this.num(zloop, 3), ikz: this.num(ikz, 0), ratio, verdict: ratio.status || null }
  }

  // ── КИПиА ────────────────────────────────────────────────────────────

  // Множители приходят с сервера, чтобы таблица на странице и формула не расходились.
  pressure(v) {
    const units = this.normsValue?.units ?? []
    const from = units.find((row) => row.unit === (v.unit || "bar"))
    if (v.value == null || !from) return Object.fromEntries(units.map((row) => [row.unit, "—"]))
    const pascals = v.value * from.pascals
    return Object.fromEntries(units.map((row) => [row.unit, this.sig(pascals / row.pascals)]))
  }

  // Пропускная способность клапана Kv — ГОСТ 23866 / IEC 60534 (турбулентный режим).
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

  // ── Сети и протоколы АСУ ТП ──────────────────────────────────────────

  // Тайминг кадра Modbus RTU (FC03) и межкадровой паузы t3.5 — по спецификации протокола.
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

  // ── Фотографу и видеографу ───────────────────────────────────────────

  // c — не константа камеры, а допущение о размере отпечатка (отсюда дисклеймер в форме).
  formats() {
    return {
      ff: { d: 43.27, w: 36, h: 24, c: 0.03 },
      apsc: { d: 28.29, w: 23.6, h: 15.6, c: 0.02 },
      m43: { d: 21.64, w: 17.3, h: 13, c: 0.015 },
      one: { d: 15.86, w: 13.2, h: 8.8, c: 0.011 }
    }
  }

  // Выдержка — правило 180° (t = 1/(2·fps)); ряд фильтров — степени двойки ND2…ND1024.
  ndFilter(v) {
    const fps = v.fps ?? 25
    const iso = v.iso ?? 100
    const n = v.n
    const ev = parseFloat(v.scene) // пресет сцены несёт EV₁₀₀ прямо в значении
    const blank = { shutter: "—", stops: { text: "—", status: "" }, nd: "—", pick: "—", resid: "—", verdict: null }
    if (fps <= 0 || iso <= 0 || n == null || n <= 0 || !Number.isFinite(ev)) return blank
    const t = 1 / (2 * fps)
    const stops = ev + Math.log2(iso / 100) - Math.log2((n * n) / t)
    const shutter = "1/" + this.num(1 / t, 0)
    // Фильтр не нужен: света и так не больше, чем нужно.
    if (stops <= 0) {
      return { shutter, stops: { text: this.num(stops, 1), status: "ok" }, nd: "—", pick: "—", resid: "—", verdict: "ok" }
    }
    const best = Math.max(1, Math.min(10, Math.round(stops)))
    return {
      shutter,
      stops: { text: this.num(stops, 1), status: "warn" },
      nd: this.num(Math.pow(2, stops), 0),
      pick: "ND" + Math.pow(2, best),
      resid: this.num(stops - best, 1),
      verdict: "warn"
    }
  }

  // Экспозиция от формата не зависит: f/2.8 одинаково ярок на любой матрице.
  cropFactor(v) {
    const fmt = this.formats()[v.format] || this.formats().ff
    const k = this.formats().ff.d / fmt.d
    const { f, n } = v
    if (f == null || f <= 0) return { feq: "—", neq: "—", noise: "—", fov: "—" }
    const fov = 2 * Math.atan(fmt.d / (2 * f)) * (180 / Math.PI)
    return {
      feq: this.num(f * k, 0),
      neq: n != null && n > 0 ? this.num(n * k, 1) : "—",
      noise: this.num(2 * Math.log2(k), 1),
      fov: this.num(fov, 0)
    }
  }

  // EV приводится к ISO 100 (EV₁₀₀), дальше решается обратная задача по параметру.
  exposureEv(v) {
    const iso = v.iso ?? 100
    const { n, ev } = v
    const tden = v.t
    const out = { ev100: "—", tneed: "—", nneed: "—", isoneed: "—" }
    if (iso <= 0) return out
    const isoShift = Math.log2(iso / 100)
    const t = tden != null && tden > 0 ? 1 / tden : null
    const hasPair = n != null && n > 0 && t != null
    if (hasPair) out.ev100 = this.num(Math.log2((n * n) / t) - isoShift, 1)
    if (ev == null) return out
    const target = ev + isoShift
    if (n != null && n > 0) {
      const tNeed = (n * n) / Math.pow(2, target)
      if (tNeed > 0) out.tneed = this.num(1 / tNeed, 0)
    }
    if (t != null) out.nneed = this.num(Math.sqrt(t * Math.pow(2, target)), 1)
    if (hasPair) out.isoneed = this.num(100 * Math.pow(2, Math.log2((n * n) / t) - ev), 0)
    return out
  }

  // Диск Эйри d = 2,44·λ·N; детализация падает, когда диск перекрывает ~2 пикселя.
  diffraction(v) {
    const fmt = this.formats()[v.format] || this.formats().ff
    const { mp, n } = v
    const LAMBDA = 0.55
    if (mp == null || mp <= 0) {
      return { pitch: "—", airy: "—", ratio: { text: "—", status: "" }, nlimit: "—", verdict: null }
    }
    const wPx = Math.sqrt(mp * 1e6 * (fmt.w / fmt.h))
    const pitch = (fmt.w / wPx) * 1000 // мм → мкм
    const out = {
      pitch: this.num(pitch, 2),
      airy: "—",
      ratio: { text: "—", status: "" },
      nlimit: this.num((2 * pitch) / (2.44 * LAMBDA), 1)
    }
    if (n != null && n > 0) {
      const airy = 2.44 * LAMBDA * n
      const ratio = airy / pitch
      out.airy = this.num(airy, 2)
      out.ratio = { text: this.num(ratio, 1), status: ratio <= 2 ? "ok" : "warn" }
      out.verdict = out.ratio.status
    }
    return out
  }

  // Дробные часы → «ЧЧ:ММ» с переносом через полночь.
  hhmm(hours) {
    if (hours == null || !Number.isFinite(hours)) return "—"
    const m = Math.round((((hours % 24) + 24) % 24) * 60) % 1440
    return String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0")
  }

  // Рельеф не учитывается — отсюда оговорка в форме.
  goldenHour(v) {
    const CUM = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    const RAD = Math.PI / 180
    const out = { sunrise: "—", sunset: "—", azrise: "—", azset: "—", golden: "—", blue: "—", hmax: "—" }
    const lat = v.lat
    if (lat == null || Math.abs(lat) > 90) return out
    const lon = v.lon ?? 0
    const tz = v.tz ?? 0
    const month = Math.max(1, Math.min(12, parseInt(v.month, 10) || 6))
    const day = Math.max(1, Math.min(31, Math.round(v.day ?? 21)))
    const b = RAD * (360 / 365) * (CUM[month - 1] + day - 81)
    const decl = 23.44 * Math.sin(b)
    const eot = 9.87 * Math.sin(2 * b) - 7.53 * Math.cos(b) - 1.5 * Math.sin(b)
    const tc = (4 * (lon - 15 * tz) + eot) / 60 // часы: местное время = солнечное − tc
    out.hmax = this.num(90 - Math.abs(lat - decl), 1)

    // Часовой угол события на высоте h, в часах; null — событие не наступает.
    const hourAngle = (h) => {
      const c =
        (Math.sin(RAD * h) - Math.sin(RAD * lat) * Math.sin(RAD * decl)) /
        (Math.cos(RAD * lat) * Math.cos(RAD * decl))
      return Math.abs(c) > 1 ? null : Math.acos(c) / RAD / 15
    }
    const evening = (ha) => this.hhmm(12 + ha - tc)

    const h0 = hourAngle(-0.833)
    if (h0 != null) {
      out.sunrise = this.hhmm(12 - h0 - tc)
      out.sunset = evening(h0)
      const cosA = Math.sin(RAD * decl) / Math.cos(RAD * lat)
      if (Math.abs(cosA) <= 1) {
        const a = Math.acos(cosA) / RAD
        out.azrise = this.num(a, 0)
        out.azset = this.num(360 - a, 0)
      }
    }
    const hUp = hourAngle(6)
    const hLow = hourAngle(-4)
    const hBlue = hourAngle(-6)
    if (hUp != null && hLow != null) out.golden = evening(hUp) + " — " + evening(hLow)
    if (hLow != null && hBlue != null) out.blue = evening(hLow) + " — " + evening(hBlue)
    return out
  }

  // Обратная задача: какой интервал даёт ролик желаемой длины при той же длительности съёмки.
  timelapse(v) {
    const { interval, duration, fps, size, wantclip } = v
    const out = { frames: "—", clip: "—", disk: "—", needint: "—" }
    const shootS = duration != null && duration > 0 ? duration * 60 : null
    if (shootS != null && interval != null && interval > 0) {
      const frames = Math.floor(shootS / interval)
      out.frames = this.num(frames, 0)
      if (fps != null && fps > 0) out.clip = this.num(frames / fps, 1)
      if (size != null && size > 0) out.disk = this.num((frames * size) / 1024, 2)
    }
    if (shootS != null && wantclip != null && wantclip > 0 && fps != null && fps > 0) {
      out.needint = this.num(shootS / (wantclip * fps), 1)
    }
    return out
  }
}
