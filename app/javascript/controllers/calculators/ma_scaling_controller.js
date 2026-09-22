// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { maScaling } from "calculators/math/kipia"

// Маркер несёт точку «мА ↔ величина» одним взглядом; выход за 4–20 мА — состояние out.
// Дублирует координаты дорожки из diagrams/_ma-scaling.html.erb.
const TRACK_START = 55
const TRACK_LENGTH = 290

export default class extends CalculatorController {
  paint(input) {
    const result = maScaling(input)

    this.render({
      eu: this.num(result.eu, 4),
      percent: this.num(result.percent, 1),
      ma: this.num(result.ma, 3)
    })
    this.#draw(input, result)
  }

  // Private

  #draw(input, result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { fraction } = result
    const clamped = fraction == null ? 0 : Math.min(1, Math.max(0, fraction))
    diagram.dataset.state =
      fraction == null ? "empty" : fraction < 0 || fraction > 1 ? "out" : "ok"

    const marker = diagram.querySelector("[data-marker]")
    if (marker) marker.style.transform = `translateX(${TRACK_START + clamped * TRACK_LENGTH}px)`

    const fill = diagram.querySelector("[data-track-fill]")
    if (fill) fill.style.transform = `scaleX(${clamped})`

    this.label({
      "signal-min": `${this.num(input.smin ?? 4, 1)} мА`,
      "signal-max": `${this.num(input.smax ?? 20, 1)} мА`,
      "range-min": this.sig(input.rmin, 4),
      "range-max": this.sig(input.rmax, 4),
      signal: input.ma == null ? this.num(null) : `${this.num(input.ma, 2)} мА`,
      value: this.sig(result.eu, 4)
    })
  }
}
