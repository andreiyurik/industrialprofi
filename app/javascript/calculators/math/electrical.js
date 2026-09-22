// @ts-check
// Чистая математика, без DOM и форматирования — та же функция кормит и текст, и схему.

/** Удельное сопротивление жилы, Ом·мм²/м. */
const RESISTIVITY = { cu: 0.0175, al: 0.0294 }

/** Норма падения напряжения для силовых и осветительных сетей, % (ПУЭ/ГОСТ). */
export const DROP_LIMIT_PERCENT = 5

/**
 * Три прохода: величина, выведенная на одном, работает входом для следующего.
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
 * ПУЭ-7, таблицы 1.3.4/1.3.6 (медь), 1.3.7/1.3.8 (алюминий); без поправочных
 * коэффициентов — отсюда дисклеймер в форме. `rows`/`index` — для схемы-лестницы.
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
 * Норма обычно 4 Ом (ПУЭ 1.7). Длина/заглубление/число электродов возвращаются
 * рядом с ответом — по ним схема рисует контур в масштабе.
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
 * Реактивным пренебрегаем — допустимо примерно до 50–95 мм².
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
