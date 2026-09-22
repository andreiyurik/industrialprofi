// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { ohmsLaw } from "calculators/math/electrical"

// Заданное — ярко своим цветом, выведенное — акцентом, пустое — приглушено.
const QUANTITIES = ["u", "i", "r", "p"]

export default class extends CalculatorController {
  paint(input) {
    const solved = ohmsLaw(input)

    this.render(Object.fromEntries(QUANTITIES.map((key) => [key, this.num(solved[key], 3)])))
    this.#draw(input, solved)
  }

  // Private

  #draw(input, solved) {
    QUANTITIES.forEach((key) => {
      const sector = this.element.querySelector(`[data-sector="${key}"]`)
      if (!sector) return

      const value = solved[key]
      sector.dataset.state = input[key] != null ? "given" : value == null ? "empty" : "derived"
      const slot = sector.querySelector("[data-sector-value]")
      // Значащие цифры, не знаки после запятой: величины гуляют от мА до кВт.
      if (slot) slot.textContent = this.sig(value, 4)
    })
  }
}
