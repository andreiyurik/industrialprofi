// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { hyperfocal } from "calculators/math/photo"

// Ось сжата функцией d/(d + H): гиперфокал — посередине, бесконечность — у правого
// края. Дублирует координаты дорожки из diagrams/_hyperfocal.html.erb.
const TRACK_START = 20
const TRACK_LENGTH = 360
// Без нижней границы ГРИП телевика (см при оси в сотни метров) читалась бы как поломка.
const MIN_ZONE = 0.012

export default class extends CalculatorController {
  paint(input) {
    // c — допущение о размере вывода, не константа камеры; coc ужесточает его под печать/кроп.
    const format = this.formats()[input.format] || this.formats().ff
    const c = format.c / (parseFloat(input.coc) || 1)
    const s = input.s != null ? input.s * 1000 : null
    const result = hyperfocal({ f: input.f, n: input.n, c, s })

    this.render({
      h: this.#metres(result.h),
      near: this.#metres(result.near),
      far: this.#metres(result.far),
      dof: this.#metres(result.dof),
      c: this.num(c, 3)
    })
    this.#draw(result, s)
  }

  // Private

  #metres(millimetres) {
    if (millimetres === Infinity) return "∞"
    return this.num(millimetres == null ? null : millimetres / 1000, 2)
  }

  #draw(result, s) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const { h, near, far } = result
    diagram.dataset.state = h == null ? "empty" : near == null ? "nofocus" : "ok"
    if (h == null) return

    const at = (distance) => (distance === Infinity ? 1 : distance / (distance + h))

    const zone = diagram.querySelector("[data-zone]")
    if (zone && near != null) {
      const from = at(near)
      const width = Math.max(at(far) - from, MIN_ZONE)
      zone.style.transform = `translateX(${from * TRACK_LENGTH}px) scaleX(${width})`
    }

    const marker = diagram.querySelector("[data-marker]")
    if (marker && s != null) marker.style.transform = `translateX(${TRACK_START + at(s) * TRACK_LENGTH}px)`

    this.label({
      focus: s == null ? this.num(null) : `${this.num(s / 1000, 2)} м`,
      hyper: `${this.num(h / 1000, 2)} м`
    })
  }
}
