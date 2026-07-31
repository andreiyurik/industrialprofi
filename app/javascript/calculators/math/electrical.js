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
