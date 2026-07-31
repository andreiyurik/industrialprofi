import { Controller } from "@hotwired/stimulus"
import { parseNumber, formatNumber, formatSignificant } from "calculators/format"

// The shared calculator controller, in two roles.
//
// 1. On its own it runs every calculator that has no diagram: the form declares
//    its formula via data-calculator-formula-value="grounding", and on each
//    input the controller gathers the fields (data-field="u" → numbers,
//    <select> → strings), calls the matching method below, and writes the
//    returned strings into the output slots (data-output="i").
// 2. As a base class it gives the per-calculator controllers in
//    controllers/calculators/ their input/output plumbing, so those files hold
//    only what is actually specific: the formula call and the diagram.
//
// Safety note: the numbers are estimates. The forms carry the normative source
// and the "сверяйтесь с проектом" disclaimer — this controller only does the
// arithmetic. Reference tables/constants are cited next to their formula.
export default class extends Controller {
  // `norms` — нормативные таблицы калькулятора, если они у него есть. Приходят
  // с сервера, потому что их же рендерит страница под расчётом: одна копия и
  // один шов под другие рынки (см. Calculator::NORMS).
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

  // What to do with the gathered input. The default drives the formula named by
  // the form; a per-calculator controller overrides this to also draw its
  // diagram, and inherits everything else untouched.
  paint(input) {
    const fn = this[this.formulaValue]
    if (typeof fn !== "function") return
    this.render(fn.call(this, input) || {})
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
        data[el.dataset.field] = parseNumber(el.value)
      }
    })
    this.#followRanges(data)
    this.#followPresets(data)
    return data
  }

  // A formula returns either a plain string per output slot, or an object
  // { text, status } — `status` ("ok"/"warn"/"") drives a verdict colour on the
  // slot and its enclosing result row (green within norm / red over it).
  // The reserved `verdict` key carries a bare status and spells the outcome out
  // in words instead; it addresses no slot of its own.
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

  // Подписи на схеме — второй вид слотов рядом с [data-output]: тот же приём
  // «имя → текст», но без статусов, потому что цвет на схеме несёт состояние
  // всей картинки, а не отдельной строки. Живёт здесь, чтобы каждый рисующий
  // контроллер не заводил себе такой же поиск по DOM.
  label(figures) {
    for (const [key, text] of Object.entries(figures)) {
      const slot = this.element.querySelector(`[data-figure="${key}"]`)
      if (slot) slot.textContent = text
    }
  }

  // Copy a headline result to the clipboard — the one thing you want from a
  // calculator mid-job. Button sits next to the value; flips to a check briefly.
  // Bound on the panel, not on each button: the identifier differs per
  // calculator, so a data-action spelled into the partial would only resolve
  // for whichever controller the partial happened to name.
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

  // ── number formatting (locale comes from <html lang>) ──
  num(value, digits = 2) {
    return formatNumber(value, digits)
  }

  sig(value, digits = 5) {
    return formatSignificant(value, digits)
  }

  // A slider is not a field of its own — only its number input carries
  // data-field, so read() can never see two values for one quantity. Dragging
  // fills the input (#mirrorRange), typing drags the slider (#followRanges).
  #mirrorRange(target) {
    const field = target?.dataset?.rangeFor
    if (!field) return
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = target.value
  }

  // Colour says it faster, words say it at all. The phrasings come from the
  // locale via data attributes, so this never holds Russian.
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

  // A preset <select> fills its number input with a typical value from a
  // reference table, so "удельное сопротивление грунта" becomes "выберите
  // грунт". Like a slider it is a helper, not a field: it never reaches read().
  #applyPreset(target) {
    const field = target?.dataset?.presetFor
    if (!field || !target.value) return
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = target.value
  }

  // ...and it steps back to "своё значение" the moment the number stops
  // matching, so the label never claims a soil the figure no longer describes.
  #followPresets(data) {
    this.element.querySelectorAll("[data-preset-for]").forEach((select) => {
      const value = data[select.dataset.presetFor]
      const match = [ ...select.options ].find((option) => option.value !== "" && Number(option.value) === value)
      select.value = match ? match.value : ""
    })
  }

  // ── Электрик ─────────────────────────────────────────────────────────

  // Ток утечки и выбор уставки УЗО (ПУЭ 7.1.83). Расчётный ток утечки: 0,4 мА
  // на 1 А тока нагрузки (естественная утечка ЭП) + 0,01 мА на 1 м фазного
  // проводника. Рабочий ток утечки должен быть ≤ 1/3 номинала УЗО — иначе
  // ложные срабатывания; отсюда цвет. (Уставка 30 мА — защита человека.)
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

  // Давление: всё через Паскали. Множители — значения единицы в Па; приходят с
  // сервера, потому что их же страница показывает таблицей (Calculator::NORMS).
  pressure(v) {
    const units = this.normsValue?.units ?? []
    const from = units.find((row) => row.unit === (v.unit || "bar"))
    if (v.value == null || !from) return Object.fromEntries(units.map((row) => [row.unit, "—"]))
    const pascals = v.value * from.pascals
    return Object.fromEntries(units.map((row) => [row.unit, this.sig(pascals / row.pascals)]))
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

  // ── Сети и протоколы АСУ ТП ──────────────────────────────────────────

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

  // ── Фотографу и видеографу ───────────────────────────────────────────

  // Параметры форматов матриц. d — диагональ (мм), из неё кроп-фактор; w/h —
  // физический размер (мм) для шага пикселя; c — кружок нерезкости: традиционные
  // 0,03 мм полного кадра, отмасштабированные по диагонали. c — не константа
  // камеры, а допущение о размере отпечатка, отсюда дисклеймер в форме.
  formats() {
    return {
      ff: { d: 43.27, w: 36, h: 24, c: 0.03 },
      apsc: { d: 28.29, w: 23.6, h: 15.6, c: 0.02 },
      m43: { d: 21.64, w: 17.3, h: 13, c: 0.015 },
      one: { d: 15.86, w: 13.2, h: 8.8, c: 0.011 }
    }
  }

  // Плотность ND. Выдержка задана правилом 180°: t = 1/(2·fps). Перебор света =
  // EV сцены, приведённый к ISO, минус EV выбранной пары: (EV + log₂(ISO/100)) −
  // log₂(N²/t). Ряд стандартных фильтров — степени двойки ND2…ND1024.
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

  // Кроп-фактор как единый множитель по трём осям сразу: угол (f·k), глубина
  // резкости (N·k) и собранный свет (2·log₂(k) стопов — площадь падает как k²).
  // Экспозиция от формата НЕ зависит: f/2.8 одинаково ярок на любой матрице.
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

  // Экспозиция и EV. EV пары = log₂(N²/t); освещённость сцены приводится к
  // ISO 100: EV₁₀₀ = log₂(N²/t) − log₂(ISO/100). Дальше от заданного EV сцены
  // решаем обратную задачу для каждого из трёх параметров по очереди.
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
    const target = ev + isoShift // требуемое log₂(N²/t)
    if (n != null && n > 0) {
      const tNeed = (n * n) / Math.pow(2, target)
      if (tNeed > 0) out.tneed = this.num(1 / tNeed, 0)
    }
    if (t != null) out.nneed = this.num(Math.sqrt(t * Math.pow(2, target)), 1)
    if (hasPair) out.isoneed = this.num(100 * Math.pow(2, Math.log2((n * n) / t) - ev), 0)
    return out
  }

  // Дифракционный предел. Диск Эйри d = 2,44·λ·N (λ = 0,55 мкм). Шаг пикселя из
  // числа мегапикселей и отношения сторон формата. Детализация начинает падать,
  // когда диск перекрывает примерно два пикселя — отсюда предельная диафрагма.
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

  // Время и азимут солнца. Склонение δ ≈ 23,44·sin(360/365·(N − 81)); уравнение
  // времени EoT = 9,87·sin2B − 7,53·cosB − 1,5·sinB. Поправка к гражданскому
  // времени TC = 4·(λ − 15·UTC) + EoT (минуты). Часовой угол события на высоте h:
  // cos H = (sin h − sin φ·sin δ)/(cos φ·cos δ); заход при h = −0,833° (рефракция
  // и радиус диска), золотой час от +6° до −4°, синий от −4° до −6°.
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


  // Интервальная съёмка: кадров = длительность съёмки ÷ интервал, ролик =
  // кадров ÷ частоту, объём = кадров × вес кадра. Обратная задача: какой интервал
  // даёт ролик желаемой длины при той же длительности съёмки.
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
