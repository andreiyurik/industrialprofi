// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { twistedPairLine } from "calculators/math/kipia"

// Линия от коммутатора до устройства и запас по длине. Верх схемы отвечает на
// «доедет ли питание» (сколько вольт ушло в кабель и сколько осталось), низ —
// на «докуда можно тянуть»: заливка ползёт до предельной длины и упирается в
// её отметку. Дублирует координаты дорожки из diagrams/_twisted-pair-line.
const TRACK_START = 4
const TRACK_LENGTH = 392

export default class extends CalculatorController {
  paint(input) {
    const result = twistedPairLine(input, this.normsValue)
    const status = result.withinLimit == null ? "" : result.withinLimit ? "ok" : "warn"

    this.render({
      rloop: this.num(result.loop, 2),
      vdrop: this.num(result.drop, 2),
      vpd: { text: this.num(result.atDevice, 1), status },
      lmax: this.num(result.maxLength, 0),
      verdict: result.withinLimit == null ? null : status
    })
    this.#draw(input, result, status)
  }

  // Private

  #draw(input, result, status) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    diagram.dataset.state = result.atDevice == null ? "empty" : status

    const length = input.l ?? 50
    const share = Math.min(1, Math.max(0, length / result.channel))
    const fill = diagram.querySelector("[data-length-fill]")
    if (fill) fill.style.transform = `scaleX(${share})`

    // Отметку показываем, только когда предел ставит питание. Если тянуть
    // мешает сам канал, она встала бы на конец шкалы и повторила бы его цифру.
    const limit = diagram.querySelector("[data-limit]")
    const limitShare = Math.min(1, (result.maxLength ?? 0) / result.channel)
    if (limit) {
      limit.dataset.state = limitShare < 1 ? "on" : "off"
      limit.style.transform = `translateX(${TRACK_START + limitShare * TRACK_LENGTH}px)`
    }

    this.label({
      source: this.#volts(result.source),
      device: this.#volts(result.atDevice),
      drop: result.drop == null ? this.num(null) : `−${this.num(result.drop, 2)} В`,
      length: `${this.num(length, 0)} м`,
      limit: result.maxLength == null ? this.num(null) : `${this.num(result.maxLength, 0)} м`,
      channel: `${this.num(result.channel, 0)} м`
    })
  }

  #volts(value) {
    return value == null ? this.num(null) : `${this.num(value, 1)} В`
  }
}
