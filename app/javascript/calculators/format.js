// @ts-check
// Number IO for the calculators, kept out of the maths so the formulas stay
// locale-agnostic: they take and return plain numbers, this file turns those
// into text for the current page language. The locale comes from <html lang>
// (Rails renders I18n.locale there), so a new market is a locale file, never
// a change here.

const FALLBACK_LOCALE = "ru"
const EMPTY = "—"

const formatters = new Map()

function formatter(options) {
  const locale = document.documentElement.lang || FALLBACK_LOCALE
  const key = `${locale}:${JSON.stringify(options)}`
  let cached = formatters.get(key)
  if (!cached) {
    cached = new Intl.NumberFormat(locale, options)
    formatters.set(key, cached)
  }
  return cached
}

/**
 * Read a number the way a person actually types it, in any market's
 * convention: "1,5" (ru/de), "1.5" (en), "1 234,5", "1,234.5". When both
 * separators appear the LAST one is the decimal mark and the other groups
 * thousands — that rule covers every locale we care about without knowing
 * which one is active.
 * @param {string|null|undefined} text
 * @returns {number|null}
 */
export function parseNumber(text) {
  const cleaned = String(text ?? "").trim().replace(/[\s  ']/g, "")
  if (!cleaned) return null

  const comma = cleaned.lastIndexOf(",")
  const dot = cleaned.lastIndexOf(".")
  let normalized = cleaned
  if (comma > -1 && dot > -1) {
    const decimal = comma > dot ? "," : "."
    normalized = cleaned.split(decimal === "," ? "." : ",").join("").replace(decimal, ".")
  } else if (comma > -1) {
    normalized = cleaned.replace(",", ".")
  }

  const value = Number.parseFloat(normalized)
  return Number.isFinite(value) ? value : null
}

/**
 * @param {number|null|undefined} value
 * @param {number} [digits] maximum decimal places
 * @returns {string}
 */
export function formatNumber(value, digits = 2) {
  if (value == null || !Number.isFinite(value)) return EMPTY
  return formatter({ maximumFractionDigits: digits }).format(value)
}

/**
 * Significant-digit form for values spanning many orders of magnitude
 * (1 МПа = 0,000145 psi … = 10 197 мм вод. ст.).
 * @param {number|null|undefined} value
 * @param {number} [digits]
 * @returns {string}
 */
export function formatSignificant(value, digits = 5) {
  if (value == null || !Number.isFinite(value)) return EMPTY
  return formatter({ maximumSignificantDigits: digits }).format(value)
}

export { EMPTY }
