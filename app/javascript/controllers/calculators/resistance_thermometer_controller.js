// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { rtdRange, rtdResistance, rtdTemperature } from "calculators/math/kipia"

// Кривая НСХ выбранного датчика во весь его рабочий диапазон и точка, в которую
// попал расчёт. Оба хода живут на одной кривой: закрашенная точка — та, что
// пришла от температуры, кольцо — та, что от сопротивления. На умолчаниях они
// совпадают, и это и есть ответ на вопрос «почему 138,5 Ом — это 100 °C».
// Дублирует координаты дорожки из diagrams/_resistance-thermometer.html.erb.
const PLOT_X = 46
const PLOT_Y = 14
const PLOT_WIDTH = 344
const PLOT_HEIGHT = 98
const SAMPLES = 40

export default class extends CalculatorController {
  paint(input) {
    const norms = this.normsValue
    const resistance = rtdResistance(norms, input.type, input.t)
    const temperature = rtdTemperature(norms, input.type, input.r)

    this.render({
      rOut: this.num(resistance, 3),
      tOut: this.num(temperature, 2)
    })
    this.#draw(input, resistance, temperature)
  }

  // Private

  #draw(input, resistance, temperature) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const norms = this.normsValue
    const [ min, max ] = rtdRange(norms, input.type)
    const low = rtdResistance(norms, input.type, min)
    const high = rtdResistance(norms, input.type, max)
    const x = (degrees) => PLOT_X + ((degrees - min) / (max - min)) * PLOT_WIDTH
    const y = (ohms) => PLOT_Y + PLOT_HEIGHT - ((ohms - low) / (high - low)) * PLOT_HEIGHT

    const curve = diagram.querySelector("[data-curve]")
    if (curve) {
      const points = []
      for (let step = 0; step <= SAMPLES; step++) {
        const degrees = min + ((max - min) * step) / SAMPLES
        points.push(`${x(degrees).toFixed(1)},${y(rtdResistance(norms, input.type, degrees)).toFixed(1)}`)
      }
      curve.setAttribute("points", points.join(" "))
    }

    this.#point(diagram, "direct", resistance == null ? null : [ x(input.t), y(resistance) ])
    this.#point(diagram, "reverse", temperature == null ? null : [ x(temperature), y(input.r) ])

    this.label({
      "t-min": `${this.num(min, 0)} °C`,
      "t-max": `${this.num(max, 0)} °C`,
      "r-min": `${this.num(low, 0)} Ом`,
      "r-max": `${this.num(high, 0)} Ом`
    })
  }

  #point(diagram, name, position) {
    const marker = diagram.querySelector(`[data-point="${name}"]`)
    if (!marker) return
    marker.dataset.state = position ? "on" : "off"
    if (position) marker.style.transform = `translate(${position[0]}px, ${position[1]}px)`
  }
}
