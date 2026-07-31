// @ts-check
// Фото и видео: чистая математика, только числа. См. комментарий в electrical.js.

/**
 * Гиперфокал и границы ГРИП. H = f²/(N·c) + f — форма, отсчитываемая от
 * передней главной плоскости; парные ей точные границы: ближняя =
 * s·(H − f)/(H + s − 2f), дальняя = s·(H − f)/(H − s). При s ≥ H ближняя даёт
 * ровно H/2, а дальняя уходит в бесконечность — её и возвращаем как Infinity,
 * чтобы «до горизонта» осталось числом и дошло до схемы, а не до строки «∞».
 * Всё в миллиметрах: и фокусное, и дистанция, и ответ.
 * @param {{f: number|null, n: number|null, c: number, s: number|null}} input
 * @returns {{h: number|null, near: number|null, far: number|null, dof: number|null}}
 */
export function hyperfocal({ f, n, c, s }) {
  const blank = { h: null, near: null, far: null, dof: null }
  if (f == null || n == null || f <= 0 || n <= 0 || !(c > 0)) return blank

  const h = (f * f) / (n * c) + f
  if (s == null || s <= f) return { ...blank, h }

  const near = (s * (h - f)) / (h + s - 2 * f)
  if (s >= h) return { h, near, far: Infinity, dof: Infinity }

  const far = (s * (h - f)) / (h - s)
  return { h, near, far, dof: far - near }
}
