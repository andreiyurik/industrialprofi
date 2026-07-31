// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { cableCrossSection } from "calculators/math/electrical"

// Лестница сечений: ступени — стандартные сечения из таблицы ПУЭ, их высота —
// длительно допустимый ток, линия поперёк — расчётный. Ответ читается сразу:
// это первая ступень, которая поднялась выше линии. Окно из пяти ступеней
// едет за ответом, поэтому мелкие сечения не сплющиваются рядом со 120 мм².
// Дублирует координаты дорожки из diagrams/_cable-cross-section.html.erb.
const STEPS = 5
const PLOT_HEIGHT = 128

export default class extends CalculatorController {
  paint(input) {
    const result = cableCrossSection(input, this.normsValue)

    this.render({
      current: this.num(result.current, 1),
      apparent: this.num(result.apparent, 2),
      section: this.#section(result),
      allowed: this.num(result.allowed, 0),
      breaker: this.num(result.breaker, 0)
    })
    this.#draw(result)
  }

  // Private

  // Ток выше последней строки таблицы — сечения в ней уже нет, но ответ «больше
  // самого толстого» честнее прочерка.
  #section(result) {
    if (result.index != null || result.current == null) return this.num(result.section, 1)
    return `> ${this.num(result.rows.at(-1)[0], 1)}`
  }

  #draw(result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { rows, index, current } = result
    diagram.dataset.state = current == null ? "empty" : "ok"

    const start = current == null ? 0 : this.#windowStart(rows.length, index)
    const visible = rows.slice(start, start + STEPS)
    const ceiling = Math.max(...visible.map(([, amps]) => amps))

    const figures = { current: current == null ? this.num(null) : `${this.num(current, 1)} А` }
    for (let slot = 0; slot < STEPS; slot++) {
      const step = diagram.querySelector(`[data-step="${slot}"]`)
      if (!step) continue

      const row = visible[slot]
      step.dataset.state = row ? (start + slot === index ? "pick" : "plain") : "off"
      if (!row) continue

      const bar = step.querySelector(".section-ladder__bar")
      if (bar) bar.style.transform = `scaleY(${row[1] / ceiling})`
      figures[`section-${slot}`] = this.num(row[0], 1)
      figures[`amps-${slot}`] = `${this.num(row[1], 0)} А`
    }
    this.label(figures)

    const line = diagram.querySelector("[data-current]")
    const share = current == null ? 0 : Math.min(1, current / ceiling)
    if (line) line.style.transform = `translateY(${-share * PLOT_HEIGHT}px)`
  }

  // Окно держит ответ третьей ступенью, пока таблица позволяет; без ответа
  // (ток выше таблицы) показываем её конец — там и идёт разговор.
  #windowStart(count, index) {
    const last = Math.max(0, count - STEPS)
    if (index == null) return last
    return Math.min(last, Math.max(0, index - 2))
  }
}
