// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { hyperfocal } from "calculators/math/photo"

// Полоса резкости от камеры до бесконечности. Ось расстояний сжата функцией
// d/(d + H), поэтому гиперфокал всегда стоит ровно посередине, а бесконечность
// помещается на экран. Наведитесь на гиперфокал — и закрашенный участок
// дотягивается до правого края: это и есть то, ради чего его считают.
// Дублирует координаты дорожки из diagrams/_hyperfocal.html.erb.
const TRACK_START = 20
const TRACK_LENGTH = 360
// Телевик на открытой диафрагме даёт ГРИП в сантиметры при оси в сотни метров:
// без нижней границы участок схлопнулся бы в ничто и читался как поломка.
const MIN_ZONE = 0.012

export default class extends CalculatorController {
  paint(input) {
    // Кружок нерезкости — допущение о размере вывода, а не константа камеры:
    // базовое значение рассчитано на обычный просмотр, делитель ужесточает его
    // под крупную печать и кадрирование.
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

    // Сжатие оси: d/(d + H). Ноль остаётся нулём, гиперфокал — серединой,
    // бесконечность — правым краем.
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
