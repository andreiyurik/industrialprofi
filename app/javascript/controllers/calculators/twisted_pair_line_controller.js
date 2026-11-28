// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { twistedPairLine } from "calculators/math/kipia"

// Координаты дублируют diagrams/_twisted-pair-line.
const START = 50
const SPAN = 266
const SCALE = 120
const SOURCE_Y = 52
const MINIMUM_Y = 78
const FLOOR_Y = 94
const SCENE_TOP = 96
const STEPS = { ArrowLeft: -1, ArrowDown: -1, ArrowRight: 1, ArrowUp: 1, PageDown: -10, PageUp: 10, Home: -SCALE, End: SCALE }

export default class extends CalculatorController {
  #offset = null
  #from = null

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

  // Actions

  grab(event) {
    if (event.button !== 0) return
    const { x, y } = this.#pointer(event)
    const onDevice = event.target.closest("[data-device]")
    if (!onDevice && y < SCENE_TOP) return

    this.#offset = onDevice ? x - (START + this.#length / SCALE * SPAN) : 0
    this.#from = onDevice ? x : null
    event.currentTarget.setPointerCapture(event.pointerId)
    event.currentTarget.dataset.dragging = ""
    if (!onDevice) this.drag(event)
  }

  drag(event) {
    if (this.#offset == null) return
    if (this.#from != null) {
      if (Math.abs(this.#pointer(event).x - this.#from) < 2) return
      this.#from = null
    }
    this.#setLength((this.#pointer(event).x - this.#offset - START) / SPAN * SCALE)
  }

  release(event) {
    this.#offset = null
    this.#from = null
    delete event.currentTarget.dataset.dragging
  }

  step(event) {
    const by = STEPS[event.key]
    if (!by) return
    event.preventDefault()
    this.#setLength(this.#length + by)
  }

  // Private

  get #length() {
    return this.read().l ?? 50
  }

  #setLength(metres) {
    const field = /** @type {HTMLInputElement} */ (this.element.querySelector("[data-field='l']"))
    const value = String(Math.min(SCALE, Math.max(1, Math.round(metres))))
    if (field.value === value) return
    field.value = value
    field.dispatchEvent(new Event("input", { bubbles: true }))
  }

  #pointer(event) {
    return new DOMPoint(event.clientX, event.clientY).matrixTransform(event.currentTarget.getScreenCTM().inverse())
  }

  #x(metres) {
    return START + Math.min(1, Math.max(0, metres / SCALE)) * SPAN
  }

  #draw(input, result, status) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const length = input.l ?? 50
    const end = this.#x(length)
    const allowance = (result.source ?? 0) - (result.minDevice ?? 0)
    // Доля запаса напряжения, съеденная кабелем: 1 — на устройстве ровно минимум.
    const used = result.drop == null ? 0 : allowance > 0 ? result.drop / allowance : 2
    const y = Math.min(FLOOR_Y, SOURCE_Y + used * (MINIMUM_Y - SOURCE_Y))
    const far = length > result.channel

    diagram.dataset.state = result.atDevice == null ? "empty" : status
    diagram.toggleAttribute("data-far", far)

    const template = diagram.dataset.metres
    const metres = (value) => template.replace("{metres}", this.num(value, 0))
    const set = (selector, attributes) => {
      const node = diagram.querySelector(selector)
      for (const [name, value] of Object.entries(attributes)) node?.setAttribute(name, String(value))
    }
    diagram.querySelectorAll("[data-stretch]").forEach((node) => node.style.transform = `scaleX(${(end - START) / SPAN})`)
    set("[data-fade]", { "stop-opacity": Math.max(0.15, 1 - 0.75 * used) })
    set("[data-profile]", { x2: end, y2: y })
    set("[data-point]", { cx: end, cy: y })
    set("[data-area]", { d: `M${START} ${SOURCE_Y} L${end} ${y} V${FLOOR_Y} H${START} Z` })
    set("[data-device]", { "aria-valuenow": Math.round(length), "aria-valuetext": metres(length) })
    diagram.querySelector("[data-device]").style.transform = `translateX(${end}px)`
    set("[data-figure='length']", { x: Math.max(START + 24, (START + end) / 2) })

    const gate = this.#x(result.channel)
    set("[data-beyond]", { x: gate, width: 356 - gate })
    set("[data-channel-line]", { x1: gate, x2: gate })
    set("[data-channel-label]", { x: gate - 5.7 })
    const channelLabel = diagram.querySelector("[data-channel-label]")
    if (channelLabel) channelLabel.textContent = channelLabel.dataset.template.replace("{channel}", this.num(result.channel, 0))

    // Отметку показываем только когда предел ставит питание, не канал.
    const powerLimits = result.maxLength != null && result.maxLength < result.channel
    const limit = this.#x(result.maxLength ?? 0)
    set("[data-limit]", { "data-state": powerLimits ? "on" : "off" })
    set("[data-limit-line]", { x1: limit, x2: limit })
    set("[data-limit-label]", { x: Math.max(130, Math.min(256, limit + 40)) })

    const figures = {
      source: this.#volts(result.source),
      device: this.#volts(result.atDevice),
      drop: result.drop == null ? this.num(null) : `−${this.num(result.drop, 2)} В`,
      minimum: this.#volts(result.minDevice),
      length: metres(length),
      channel: this.num(result.channel, 0),
      limit: result.maxLength == null ? this.num(null) : metres(result.maxLength)
    }
    this.label(figures)
    this.#explain(result.atDevice == null ? "empty" : status === "ok" && far ? "far" : status, figures)
  }

  #explain(state, figures) {
    const line = /** @type {HTMLElement} */ (this.element.querySelector("[data-says]"))
    if (!line) return
    const phrase = line.getAttribute(`data-says-${state}`) ?? ""
    const text = phrase.replace(/\{(\w+)\}/g, (_, key) => figures[key]?.replace("−", ""))
    if (line.textContent !== text) line.textContent = text
    line.dataset.state = state
  }

  #volts(value) {
    return value == null ? this.num(null) : `${this.num(value, 1)} В`
  }
}
