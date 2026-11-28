// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { modbusRtu } from "calculators/math/kipia"

const REQUEST_BYTES = 8
const SLOWDOWN = 50
const LONGEST_POLL = 12000
// Координаты дублируют diagrams/_modbus-rtu.html.erb.
const MASTER_X = 46
const BUS_Y = 122
const SLAVES_FROM = 112
const SLAVES_SPAN = 280
const SLOTS = 5
const ORDER = [ "request", "gap", "delay", "response", "gap" ]

export default class extends CalculatorController {
  #poll = null
  #elapsed = 0
  #device = 0
  #frame = null
  #last = null
  #paused = null

  // Lifecycle

  disconnect() {
    this.#stop()
  }

  paint(input) {
    this.render(this.modbusRtu(input))
    this.#paused ??= window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.#prepare(input)
  }

  // Actions

  toggle() {
    this.#paused = !this.#paused
    this.#run()
  }

  seek({ params: { phase } }) {
    if (!this.#poll) return
    const step = this.#poll.steps.find((it) => it.phase === phase && it.length > 0)
    if (!step) return
    this.#elapsed = step.from + step.length * 0.55
    this.#paused = true
    this.#run()
  }

  // Private

  #prepare(input) {
    const figure = this.#find("[data-diagram]")
    const result = modbusRtu({ ...input, delay: Math.max(0, input.delay ?? 0) })
    const total = result.transaction

    if (total == null || !(total > 0)) {
      this.#poll = null
      this.#stop()
      figure.dataset.state = "empty"
      figure.dataset.phase = ""
      this.element.querySelectorAll("[data-active]").forEach((el) => el.removeAttribute("data-active"))
      this.#find("[data-summary]").textContent = figure.dataset.tplInvalid
      for (const phase of new Set(ORDER)) this.label({ [`${phase}-ms`]: "—", [`${phase}-share`]: "" })
      this.label({ cycle: "—" })
      return
    }

    const charMs = ((parseFloat(input.bpc) || 11) / (parseFloat(input.baud) || 9600)) * 1000
    const request = REQUEST_BYTES * charMs
    const response = result.respBytes * charMs
    const delay = Math.max(0, input.delay ?? 0)
    const gap = Math.max(0, total - request - response - delay) / 2
    const lengths = { request, gap, delay, response }

    let from = 0
    const steps = ORDER.map((phase) => {
      const step = { phase, from, length: lengths[phase] }
      from += step.length
      return step
    })

    // Without autoplay the first frame has to show a transfer in progress.
    const still = this.#paused ? (request + gap + delay + response / 2) / from : 0
    const share = this.#poll ? this.#elapsed / this.#poll.total : still
    const devices = Math.max(1, Math.round(input.dev ?? 1))
    const factor = Math.min(SLOWDOWN, LONGEST_POLL / from)
    this.#poll = { steps, total: from, devices, factor, bytes: { request: REQUEST_BYTES, response: result.respBytes } }
    this.#elapsed = share * from
    this.#device %= devices

    figure.dataset.state = "ok"
    this.#placeSlaves()
    this.#describe(figure, { ...lengths, gap: gap * 2 }, result.cycle)
    this.#run()
  }

  #describe(figure, parts, cycle) {
    const { steps, total, devices, factor } = this.#poll
    const segments = this.element.querySelectorAll("[data-segment]")
    steps.forEach((step, i) => segments[i].style.flexGrow = String(step.length / total))

    for (const [ phase, ms ] of Object.entries(parts)) {
      this.label({
        [`${phase}-ms`]: this.#fill(figure.dataset.tplMs, { value: this.num(ms, ms < 10 ? 2 : 1) }),
        [`${phase}-share`]: `${this.num((ms / total) * 100, 0)} %`
      })
    }
    this.label({ cycle: this.#fill(figure.dataset.tplCycle, { dev: devices, one: this.num(total, 1), total: this.num(cycle, 1) }) })

    const [ most, ms ] = Object.entries(parts).sort((a, b) => b[1] - a[1])[0]
    const key = `tplMost${most[0].toUpperCase()}${most.slice(1)}`
    this.#find("[data-summary]").textContent = this.#fill(devices > 1 ? figure.dataset.tplSummary : figure.dataset.tplSummaryOne, {
      dev: devices,
      total: cycle < 1000
        ? this.#fill(figure.dataset.tplMs, { value: this.num(cycle, 1) })
        : this.#fill(figure.dataset.tplSeconds, { value: this.num(cycle / 1000, 2) }),
      most: figure.dataset[key],
      share: this.num((ms / total) * 100, 0)
    })
    this.#find("[data-slow]").textContent = this.#fill(figure.dataset.tplSlow, { factor: this.num(factor, factor < 10 ? 1 : 0) })
    this.#find(".mbus__round").style.setProperty("--devices", String(Math.min(devices, 60)))
    this.#find("[data-turn]").style.inlineSize = `${Math.max(100 / devices, 1)}%`
  }

  #placeSlaves() {
    const shown = Math.min(this.#poll.devices, SLOTS)
    this.element.querySelectorAll("[data-slot]").forEach((slot, i) => {
      slot.toggleAttribute("hidden", i >= shown)
      slot.setAttribute("transform", `translate(${this.#slotX(i)} 0)`)
    })
  }

  #slotX(slot) {
    const shown = Math.min(this.#poll.devices, SLOTS)
    return SLAVES_FROM + (slot + 0.5) * (SLAVES_SPAN / shown)
  }

  // Past five devices the fourth box stands for everyone between the third and the last.
  #slotFor(device) {
    const { devices } = this.#poll
    if (devices <= SLOTS || device < SLOTS - 2) return device
    return device === devices - 1 ? SLOTS - 1 : SLOTS - 2
  }

  #run() {
    const button = this.#find("[data-play]")
    this.#find("[data-diagram]").toggleAttribute("data-paused", this.#paused)
    button.textContent = this.#paused ? button.dataset.playLabel : button.dataset.pauseLabel
    if (!this.#poll) return

    this.#stop()
    this.#draw()
    if (!this.#paused) this.#frame = requestAnimationFrame(this.#tick)
  }

  #stop() {
    cancelAnimationFrame(this.#frame)
    this.#last = null
  }

  #tick = (now) => {
    // A background tab must not fast-forward on return.
    const passed = this.#last == null ? 0 : Math.min(now - this.#last, 100)
    this.#last = now
    this.#elapsed += passed / this.#poll.factor
    while (this.#elapsed >= this.#poll.total) {
      this.#elapsed -= this.#poll.total
      this.#device = (this.#device + 1) % this.#poll.devices
    }
    this.#draw()
    this.#frame = requestAnimationFrame(this.#tick)
  }

  #draw() {
    const figure = this.#find("[data-diagram]")
    const { steps, total, devices, bytes } = this.#poll
    const step = steps.findLast((it) => it.length > 0 && it.from <= this.#elapsed) ?? steps[0]
    const progress = Math.min(1, (this.#elapsed - step.from) / step.length)
    const slot = this.#slotFor(this.#device)
    const x = this.#slotX(slot)
    const address = this.#device + 1

    figure.dataset.phase = step.phase

    this.element.querySelectorAll("[data-slot]").forEach((el, i) => {
      el.toggleAttribute("data-active", i === slot)
      const number = (n) => this.#fill(figure.dataset.tplAddress, { n })
      let label = number(i + 1)
      if (devices > SLOTS && i === SLOTS - 1) label = number(devices)
      if (devices > SLOTS && i === SLOTS - 2) label = i === slot ? number(address) : figure.dataset.tplSkipped
      el.querySelector("[data-address]").textContent = label
    })

    const route = `M${MASTER_X} 88V${BUS_Y}H${x}V88`
    this.#find("[data-wire]").setAttribute("d", route)
    this.#find("[data-flow]").setAttribute("d", step.phase === "response" ? `M${x} 88V${BUS_Y}H${MASTER_X}V88` : route)
    this.#find("[data-think]").setAttribute("transform", `translate(${x} 0)`)

    if (step.phase === "request" || step.phase === "response") {
      const count = bytes[step.phase]
      const width = Math.min(110, 26 + count * 0.9)
      const [ start, end ] = step.phase === "request" ? [ MASTER_X, x ] : [ x, MASTER_X ]
      const centre = Math.max(width / 2 + 4, Math.min(396 - width / 2, start + (end - start) * progress))
      const cells = Math.min(count, Math.floor(width / 6))
      const pitch = (width - 8) / cells
      this.#find("[data-capsule]").setAttribute("x", String(-width / 2))
      this.#find("[data-capsule]").setAttribute("width", String(width))
      this.#find("[data-bits]").setAttribute("d",
        Array.from({ length: cells }, (_, i) => `M${-width / 2 + 4 + pitch * (i + 0.5)} 117v10`).join(""))
      this.#find("[data-size]").textContent = this.#fill(figure.dataset.tplBytes, { count })
      this.#find("[data-packet]").setAttribute("transform", `translate(${centre} 0)`)
    }

    this.#find("[data-say]").textContent = this.#fill(figure.dataset[`tplSay${step.phase[0].toUpperCase()}${step.phase.slice(1)}`], { address })
    this.#find("[data-clock]").textContent =
      this.#fill(figure.dataset.tplClock, { now: this.num(this.#elapsed, 1), total: this.num(total, 1) })
    this.#find("[data-playhead]").style.insetInlineStart = `${(this.#elapsed / total) * 100}%`
    this.#find("[data-turn]").style.insetInlineStart = `${Math.min(this.#device / devices * 100, 99)}%`
    this.element.querySelectorAll("[data-chip-phase]").forEach((chip) =>
      chip.toggleAttribute("data-active", chip.dataset.chipPhase === step.phase))
  }

  #fill(template, values) {
    return template.replace(/%\{(\w+)\}/g, (_, key) => values[key])
  }

  #find(selector) {
    return /** @type {HTMLElement} */ (this.element.querySelector(selector))
  }
}
