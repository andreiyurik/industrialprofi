// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { voltageDrop, DROP_LIMIT_PERCENT } from "calculators/math/electrical"

// Линия от щита до потребителя плюс шкала падения против нормы. Тяните
// ползунок длины — заполнение ползёт вправо и краснеет ровно там, где линия
// перестаёт укладываться в норму; это и есть ответ, ради которого сюда пришли.
const SCALE_MAX_PERCENT = 10

export default class extends CalculatorController {
  paint(input) {
    const result = voltageDrop(input)

    this.render({
      du: this.num(result.drop, 2),
      dupct: { text: this.num(result.percent, 2), status: this.#status(result) },
      verdict: result.withinLimit == null ? null : this.#status(result)
    })
    this.#draw(input, result)
  }

  // Private

  #status(result) {
    if (result.withinLimit == null) return ""
    return result.withinLimit ? "ok" : "warn"
  }

  #draw(input, result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    diagram.dataset.state = result.percent == null ? "empty" : this.#status(result)

    // Заполнение через scaleX, а не через ширину: transform анимируется CSS-ом
    // в любом браузере, геометрические свойства SVG — не везде.
    const fill = diagram.querySelector("[data-drop-fill]")
    if (fill) {
      const share = Math.min(1, Math.max(0, (result.percent ?? 0) / SCALE_MAX_PERCENT))
      fill.style.transform = `scaleX(${share})`
    }

    this.#label(diagram, "limit", `${this.num(DROP_LIMIT_PERCENT, 0)} %`)
    this.#label(diagram, "source", input.u == null ? this.num(null) : `${this.num(input.u, 0)} В`)
    this.#label(diagram, "load", result.remaining == null ? this.num(null) : `${this.num(result.remaining, 1)} В`)
    this.#label(diagram, "length", input.l == null ? this.num(null) : `${this.num(input.l, 0)} м`)
    this.#label(diagram, "drop", result.percent == null ? this.num(null) : `−${this.num(result.percent, 1)} %`)
  }

  #label(diagram, name, text) {
    const slot = diagram.querySelector(`[data-figure="${name}"]`)
    if (slot) slot.textContent = text
  }
}
