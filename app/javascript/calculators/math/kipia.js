// @ts-check
// КИПиА: чистая математика, только числа. См. комментарий в electrical.js.

/**
 * Линейное масштабирование токовой петли ↔ инженерные единицы. Считает обе
 * стороны по одному диапазону: ток → величина (и доля диапазона) и величина →
 * ток. `fraction` — положение сигнала в диапазоне, 0…1 (может выходить за
 * границы, если пользователь ввёл ток вне 4–20 мА).
 * @param {{rmin: number|null, rmax: number|null, smin: number|null,
 *          smax: number|null, ma: number|null, eu: number|null}} input
 * @returns {{eu: number|null, percent: number|null, fraction: number|null, ma: number|null}}
 */
export function maScaling(input) {
  const { rmin, rmax } = input
  const smin = input.smin ?? 4
  const smax = input.smax ?? 20
  const signalSpan = smax - smin
  const euSpan = rmin != null && rmax != null ? rmax - rmin : null

  let eu = null
  let fraction = null
  if (input.ma != null && euSpan != null && signalSpan) {
    fraction = (input.ma - smin) / signalSpan
    eu = rmin + fraction * euSpan
  }

  let ma = null
  if (input.eu != null && euSpan && rmin != null) {
    ma = smin + ((input.eu - rmin) / euSpan) * signalSpan
  }

  return { eu, percent: fraction == null ? null : fraction * 100, fraction, ma }
}
