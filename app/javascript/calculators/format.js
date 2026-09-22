// @ts-check
// Kept out of the maths so formulas stay locale-agnostic (plain numbers in/out).
// Locale comes from <html lang> — a new market is a locale file, never a code change.

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
 * "1,5" (ru/de), "1.5" (en), "1 234,5", "1,234.5" — when both separators
 * appear, the LAST one is decimal; covers every locale without detection.
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
