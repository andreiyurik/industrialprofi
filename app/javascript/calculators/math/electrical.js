// @ts-check
// Электрик: чистая математика, только числа на входе и на выходе. Никакого DOM
// и никакого форматирования — это позволяет одной и той же функции кормить и
// текстовый результат, и схему рядом с ним.

/** Удельное сопротивление жилы, Ом·мм²/м. */
const RESISTIVITY = { cu: 0.0175, al: 0.0294 }

/** Норма падения напряжения для силовых и осветительных сетей, % (ПУЭ/ГОСТ). */
export const DROP_LIMIT_PERCENT = 5

/**
 * Колесо закона Ома: любые два из U, I, R, P дают остальные два. Три прохода —
 * чтобы величина, выведенная на одном проходе, работала входом для следующего.
 * @param {{u: number|null, i: number|null, r: number|null, p: number|null}} input
 * @returns {{u: number|null, i: number|null, r: number|null, p: number|null}}
 */
export function ohmsLaw(input) {
  let { u, i, r, p } = input
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
  return { u, i, r, p }
}

/**
 * Подбор сечения по длительно допустимому току (ПУЭ-7, таблицы 1.3.4/1.3.6 —
 * медь, 1.3.7/1.3.8 — алюминий; провода/кабели с ПВХ/резиновой изоляцией).
 * Базовый расчёт без поправочных коэффициентов (температура, группировка) —
 * отсюда дисклеймер в форме. Берём наименьшее стандартное сечение, чей
 * допустимый ток ≥ расчётного. Рекомендуемый автомат: стандартный номинал,
 * который защищает кабель (Iₙ ≤ Iдоп) и пропускает рабочий ток (Iₙ ≥ Iрасч) —
 * берём наибольший подходящий из ряда; итог — с учётом селективности.
 * Таблицы приходят снаружи (Calculator::NORMS), поэтому здесь только выбор.
 * `rows`/`index` возвращаются рядом с ответом: по ним схема рисует лестницу.
 * @param {{p: number|null, i: number|null, u: number|null, cos: number|null,
 *          material: string, laying: string, phase: string}} input
 * @param {{sections: Object, breakers: number[]}} norms
 * @returns {{current: number|null, apparent: number|null, section: number|null,
 *            allowed: number|null, breaker: number|null, rows: number[][], index: number|null}}
 */
export function cableCrossSection(input, norms) {
  const sections = norms?.sections
  const rows = sections ? (sections[input.material] || sections.cu)[input.laying === "pipe" ? "pipe" : "air"] : []
  const blank = { current: null, apparent: null, section: null, allowed: null, breaker: null, rows, index: null }

  const u = input.u ?? (input.phase === "1" ? 220 : 380)
  const cos = input.cos ?? 0.95
  let current = input.i
  if (current == null && input.p != null) {
    const denom = input.phase === "1" ? u * cos : Math.sqrt(3) * u * cos
    current = denom ? (input.p * 1000) / denom : null
  }
  if (current == null || !rows.length) return blank

  const found = rows.findIndex(([, amps]) => amps >= current)
  const index = found === -1 ? null : found
  const pick = index == null ? null : rows[index]
  const breaker = pick ? (norms.breakers ?? []).filter((rating) => rating >= current && rating <= pick[1]).pop() : null
  // Полная мощность S (кВА) — по ней подбирают генератор, ИБП, трансформатор.
  const apparent = ((input.phase === "1" ? u : Math.sqrt(3) * u) * current) / 1000

  return {
    current,
    apparent,
    section: pick ? pick[0] : null,
    allowed: pick ? pick[1] : null,
    breaker: breaker ?? null,
    rows,
    index
  }
}

/**
 * Сопротивление заземляющего устройства из вертикальных электродов.
 * Одиночный электрод (стержень у поверхности): R₁ = ρ/(2π·L)·[ln(2L/d) +
 * 0,5·ln((4t+L)/(4t−L))], t = h + L/2 — глубина до середины электрода.
 * ρ берётся расчётным: ρ·ψ (ψ — сезонный/климатический коэффициент).
 * Группа из n электродов с коэффициентом использования η: Rгр = R₁/(n·η).
 * Норма обычно 4 Ом (ПУЭ 1.7) — отсюда требуемое число электродов.
 * Длину, заглубление и число электродов возвращаем рядом с ответом: по ним
 * схема рисует контур в масштабе, не переоткрывая умолчания.
 * @param {{rho: number|null, psi: number|null, l: number|null, d: number|null,
 *          h: number|null, n: number|null, eta: number|null, target: number|null}} input
 * @returns {{single: number|null, group: number|null, required: number|null,
 *            withinTarget: boolean|null, length: number, depth: number, count: number}}
 */
export function grounding(input) {
  const rho = (input.rho ?? 100) * (input.psi ?? 1.5)
  const length = input.l ?? 3
  const diameter = (input.d ?? 16) / 1000 // мм → м
  const depth = input.h ?? 0.7
  const count = Math.max(1, Math.round(input.n ?? 1))
  const eta = input.eta != null && input.eta > 0 ? input.eta : 1
  const target = input.target != null && input.target > 0 ? input.target : 4
  const shape = { length, depth, count }
  if (length <= 0 || diameter <= 0 || rho <= 0) {
    return { single: null, group: null, required: null, withinTarget: null, ...shape }
  }

  const middle = depth + length / 2
  const single =
    (rho / (2 * Math.PI * length)) *
    (Math.log((2 * length) / diameter) + 0.5 * Math.log((4 * middle + length) / (4 * middle - length)))
  const group = single / (count * eta)

  return {
    single,
    group,
    required: Math.ceil(single / (target * eta)),
    withinTarget: group <= target,
    ...shape
  }
}

/**
 * Падение напряжения в линии по активному сопротивлению жилы (реактивным
 * пренебрегаем — допустимо примерно до 50–95 мм²). L — длина в одну сторону.
 * 1-ф: ΔU = 2·ρ·L·I/S; 3-ф: ΔU = √3·ρ·L·I/S.
 * @param {{l: number|null, i: number|null, s: number|null, u: number|null,
 *          material: string, phase: string}} input
 * @returns {{drop: number|null, percent: number|null, remaining: number|null, withinLimit: boolean|null}}
 */
export function voltageDrop(input) {
  const { l, i, s, u } = input
  if (l == null || i == null || s == null || s === 0) {
    return { drop: null, percent: null, remaining: null, withinLimit: null }
  }

  const rho = RESISTIVITY[input.material] ?? RESISTIVITY.cu
  const k = input.phase === "1" ? 2 : Math.sqrt(3)
  const drop = (k * rho * l * i) / s
  const percent = u ? (drop / u) * 100 : null

  return {
    drop,
    percent,
    remaining: u ? u - drop : null,
    withinLimit: percent == null ? null : percent <= DROP_LIMIT_PERCENT
  }
}
