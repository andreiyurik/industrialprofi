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

// Термосопротивления (ТСМ/ТСП/Pt) по ГОСТ 6651-2009: оба хода между
// температурой и сопротивлением. Сами НСХ — коэффициенты, диапазоны и R₀ —
// приходят снаружи (Calculator::RTD_NORMS): в коде остаётся форма уравнения
// Каллендара–Ван Дюзена, а у меди она своя, с дополнительным членом ниже нуля.
const COPPER = "m"

function sensor(norms, type) {
  return norms?.sensors?.find((row) => row.type === type) ?? norms?.sensors?.[0] ?? null
}

function material(norms, type) {
  const found = sensor(norms, type)
  return found ? norms.materials[found.material] : null
}

/** W(t) = Rt/R0 — отношение сопротивлений. */
function ratio(norms, type, temperature) {
  const k = material(norms, type)
  if (sensor(norms, type).material === COPPER) {
    if (temperature >= 0) return 1 + k.a * temperature
    return 1 + k.a * temperature + k.b * temperature * (temperature + 6.7) + k.c * temperature ** 3
  }
  if (temperature >= 0) return 1 + k.a * temperature + k.b * temperature * temperature
  return (
    1 + k.a * temperature + k.b * temperature * temperature + k.c * (temperature - 100) * temperature ** 3
  )
}

/**
 * Рабочий диапазон датчика, °C.
 * @param {Object} norms
 * @param {string} type
 * @returns {number[]|null}
 */
export function rtdRange(norms, type) {
  return material(norms, type)?.range ?? null
}

/**
 * Прямой ход: температура → сопротивление, Ом. Вне диапазона датчика — null:
 * НСХ там не определена, и выдумывать её продолжение мы не станем.
 * @param {Object} norms
 * @param {string} type
 * @param {number|null} temperature
 * @returns {number|null}
 */
export function rtdResistance(norms, type, temperature) {
  const range = rtdRange(norms, type)
  if (temperature == null || !range) return null
  if (temperature < range[0] || temperature > range[1]) return null
  return sensor(norms, type).r0 * ratio(norms, type, temperature)
}

/**
 * Обратный ход: сопротивление → температура, °C. Делением отрезка (W монотонна
 * по t), без таблиц обратных коэффициентов.
 * @param {Object} norms
 * @param {string} type
 * @param {number|null} resistance
 * @returns {number|null}
 */
export function rtdTemperature(norms, type, resistance) {
  const range = rtdRange(norms, type)
  if (resistance == null || resistance <= 0 || !range) return null

  const target = resistance / sensor(norms, type).r0
  if (target <= ratio(norms, type, range[0]) || target >= ratio(norms, type, range[1])) return null

  let low = range[0]
  let high = range[1]
  for (let step = 0; step < 60; step++) {
    const middle = (low + high) / 2
    if (ratio(norms, type, middle) < target) low = middle
    else high = middle
  }
  return (low + high) / 2
}

/**
 * Погрешность измерения и поверка по классу точности (ГОСТ 8.401). Абсолютная
 * Δ = изм − действ; относительная δ = Δ/действ·100 %; приведённая
 * γ = Δ/Xн·100 % (Xн — нормирующее значение, обычно верхний предел диапазона).
 * Прибор годен, если |γ| ≤ класса точности — по этому же сравнению шкала
 * допуска решает, попала метка в полосу или вышла из неё.
 * @param {{measured: number|null, actual: number|null, span: number|null, cls: number|null}} input
 * @returns {{abs: number|null, rel: number|null, reduced: number|null,
 *            limit: number|null, withinClass: boolean|null}}
 */
export function measurementError(input) {
  const { measured, actual, span, cls } = input
  if (measured == null || actual == null) {
    return { abs: null, rel: null, reduced: null, limit: null, withinClass: null }
  }

  const abs = measured - actual
  const reduced = span != null && span !== 0 ? (abs / span) * 100 : null

  return {
    abs,
    rel: actual !== 0 ? (abs / actual) * 100 : null,
    reduced,
    limit: cls,
    withinClass: cls == null || reduced == null ? null : Math.abs(reduced) <= cls
  }
}

// ── Сети и протоколы АСУ ТП ──────────────────────────────────────────

/**
 * Линия витой пары с питанием PoE: падение напряжения и запас по длине.
 * R жилы (Ом/м, медь 20 °C) — по калибру AWG. PoE 2 пары (802.3af/at):
 * шлейф = Rж·L; 4 пары (802.3bt): жилы параллелятся → шлейф = Rж·L/2.
 * ΔU = I·Rшлейфа; U на устройстве = Uисточника − ΔU (должно быть ≥ Umin PD).
 * Предельная длина упирается либо в это Umin, либо в длину канала.
 * Таблицы приходят снаружи (Calculator::NORMS) — те же, что видит читатель.
 * @param {{awg: string, std: string, l: number|null, i: number|null, vpse: number|null}} input
 * @param {{awg: Object[], poe: Object[], channel_metres: number}} norms
 * @returns {{loop: number|null, drop: number|null, atDevice: number|null,
 *            maxLength: number|null, channel: number, minDevice: number|null,
 *            source: number|null, current: number|null, withinLimit: boolean|null}}
 */
export function twistedPairLine(input, norms) {
  const channel = norms?.channel_metres ?? 100
  const wire = norms?.awg?.find((row) => String(row.awg) === String(input.awg)) ?? norms?.awg?.[1]
  const standard = norms?.poe?.find((row) => row.std === input.std) ?? norms?.poe?.[1]
  const blank = {
    loop: null, drop: null, atDevice: null, maxLength: null, channel,
    minDevice: standard?.minimum ?? null, source: null, current: null, withinLimit: null
  }
  if (!wire || !standard) return blank

  const length = input.l ?? 50
  const current = input.i ?? standard.current
  const source = input.vpse ?? standard.source
  if (length < 0 || current <= 0) return { ...blank, source, current }

  const perMetre = wire.ohms_per_metre
  const loop = standard.pairs === 2 ? perMetre * length : (perMetre * length) / 2
  const drop = current * loop
  const atDevice = source - drop
  const loopMax = (source - standard.minimum) / current
  const maxLength = standard.pairs === 2 ? loopMax / perMetre : (loopMax * 2) / perMetre

  return {
    loop,
    drop,
    atDevice,
    maxLength: Math.max(0, Math.min(maxLength, channel)),
    channel,
    minDevice: standard.minimum,
    source,
    current,
    withinLimit: atDevice >= standard.minimum
  }
}

/**
 * Подсеть IPv4 по адресу и префиксу CIDR: чистая битовая арифметика
 * (>>> 0 — беззнаковые 32 бита). Адреса возвращаются числами — точки
 * расставляет toDottedQuad, а линейка бит считает прямо по префиксу.
 * Бесклассовая адресация — RFC 4632; /31 и /32 — особый случай RFC 3021:
 * там адрес сети и широковещательный тоже раздаются хостам.
 * @param {{ip: string|null, prefix: number|null}} input
 * @returns {{prefix: number|null, ip: number|null, network: number|null,
 *            mask: number|null, wildcard: number|null, broadcast: number|null,
 *            hostmin: number|null, hostmax: number|null, hosts: number|null}}
 */
export function subnet(input) {
  const blank = {
    prefix: null, ip: null, network: null, mask: null, wildcard: null,
    broadcast: null, hostmin: null, hostmax: null, hosts: null
  }
  const parts = (input.ip || "").match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
  if (!parts || input.prefix == null || input.prefix < 0 || input.prefix > 32) return blank

  const octets = parts.slice(1, 5).map(Number)
  if (octets.some((octet) => octet > 255)) return blank

  const prefix = Math.floor(input.prefix)
  const ip = ((octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3]) >>> 0
  const mask = prefix === 0 ? 0 : (0xffffffff << (32 - prefix)) >>> 0
  const network = (ip & mask) >>> 0
  const broadcast = (network | (~mask >>> 0)) >>> 0
  const narrow = prefix >= 31

  return {
    prefix,
    ip,
    network,
    mask,
    wildcard: ~mask >>> 0,
    broadcast,
    hostmin: narrow ? network : (network + 1) >>> 0,
    hostmax: narrow ? broadcast : (broadcast - 1) >>> 0,
    hosts: narrow ? (prefix === 32 ? 1 : 2) : Math.pow(2, 32 - prefix) - 2
  }
}

/**
 * 32-битный адрес → привычная запись через точки. Точки в адресе — не разряды
 * числа, поэтому это не форматирование локали, а часть самой записи.
 * @param {number|null} value
 * @returns {string|null}
 */
export function toDottedQuad(value) {
  if (value == null) return null
  return [(value >>> 24) & 255, (value >>> 16) & 255, (value >>> 8) & 255, value & 255].join(".")
}
