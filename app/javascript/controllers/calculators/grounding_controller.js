// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { grounding } from "calculators/math/electrical"

// Контур в разрезе грунта. Сплошные электроды — забитые, пунктирные — те,
// которых не хватает до нормы: главный вопрос заземления «сколько ещё штук»
// перестаёт быть числом в строке результата и становится картинкой.
// Дублирует координаты дорожки из diagrams/_grounding.html.erb.
const RODS = 12
const SURFACE = 38
const SOIL_DEPTH = 84 // px на видимую толщу грунта
const METRE = 14 // px на метр, пока контур в неё помещается

export default class extends CalculatorController {
  paint(input) {
    const result = grounding({ ...input, psi: parseFloat(input.psi) || null })
    const status = result.withinTarget == null ? "" : result.withinTarget ? "ok" : "warn"

    this.render({
      r1: this.num(result.single, 2),
      rgroup: { text: this.num(result.group, 2), status },
      nreq: this.num(result.required, 0),
      verdict: result.withinTarget == null ? null : status
    })
    this.#draw(result)
  }

  // Private

  #draw(result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { length, depth, count, required } = result
    diagram.dataset.state = result.single == null ? "empty" : "ok"

    // Масштаб постоянный, пока контур влезает в грунт: тогда более длинный
    // электрод виден как более длинный, а не как та же палка в другой рамке.
    const scale = Math.min(METRE, SOIL_DEPTH / (depth + length))
    const rods = diagram.querySelector("[data-rods]")
    if (rods) rods.style.transform = `translateY(${depth * scale}px) scaleY(${(length * scale) / SOIL_DEPTH})`

    const needed = required ?? count
    diagram.querySelectorAll("[data-rod]").forEach((rod, index) => {
      rod.dataset.state = index < count ? "set" : index < needed ? "needed" : "off"
    })

    const more = diagram.querySelector("[data-more]")
    if (more) more.dataset.state = Math.max(count, needed) > RODS ? "on" : "off"
  }
}
