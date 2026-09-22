// @ts-check
// Фото и видео: чистая математика, только числа. См. комментарий в electrical.js.

/**
 * far возвращается как Infinity, не строка «∞» — доходит числом до схемы.
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
