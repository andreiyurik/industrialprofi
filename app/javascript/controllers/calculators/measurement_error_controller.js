// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { measurementError } from "calculators/math/kipia"
import { EMPTY } from "calculators/format"

// Шкала допуска: полоса — класс точности прибора, метка — его приведённая
// погрешность. Годен или не годен перестаёт быть сравнением двух чисел в
// голове: метка либо внутри полосы, либо снаружи. Масштаб шкалы подстраивается
// под большее из двух, поэтому и допуск, и промах видны в любом случае.
// Дублирует координаты дорожки из diagrams/_measurement-error.html.erb.
const CENTRE = 200
const HALF_WIDTH = 176
const HEADROOM = 1.25

export default class extends CalculatorController {
  paint(input) {
    const result = measurementError(input)
    const status = this.#status(result)

    this.render({
      abs: this.num(result.abs, 4),
      rel: this.num(result.rel, 3),
      red: { text: this.num(result.reduced, 3), status },
      limit: result.limit == null ? EMPTY : `± ${this.num(result.limit, 2)}`,
      verdict: result.withinClass == null ? null : status
    })
    this.#draw(result, status)
  }

  // Private

  #status(result) {
    if (result.withinClass == null) return ""
    return result.withinClass ? "ok" : "warn"
  }

  #draw(result, status) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { reduced, limit } = result
    diagram.dataset.state = reduced == null ? "empty" : status || "plain"

    // Шкала всегда шире и допуска, и самой погрешности — иначе одно из двух
    // упёрлось бы в край и перестало читаться.
    const halfRange = Math.max(Math.abs(reduced ?? 0), Math.abs(limit ?? 0)) * HEADROOM || 1

    const band = diagram.querySelector("[data-band]")
    if (band) band.style.transform = `scaleX(${limit ? Math.min(1, Math.abs(limit) / halfRange) : 0})`

    const marker = diagram.querySelector("[data-marker]")
    const offset = Math.max(-1, Math.min(1, (reduced ?? 0) / halfRange)) * HALF_WIDTH
    if (marker) marker.style.transform = `translateX(${CENTRE + offset}px)`

    this.label({
      limit: limit == null ? EMPTY : `± ${this.num(limit, 2)} %`,
      value: reduced == null ? EMPTY : `${this.num(reduced, 2)} %`
    })
  }
}
