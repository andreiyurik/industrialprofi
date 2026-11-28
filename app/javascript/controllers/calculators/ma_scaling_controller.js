// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { maScaling } from "calculators/math/kipia"

// Tank geometry mirrors diagrams/_ma-scaling.html.erb.
const TANK_TOP = 40
const TANK_HEIGHT = 136
const SCALE_END = 24
// NAMUR NE 43 failure thresholds, meaningful only for a 4–20 mA signal.
const FAULT_LOW = 3.6
const FAULT_HIGH = 21
const BREAK_BELOW = 0.5

const clamp = (value, min, max) => Math.min(max, Math.max(min, value))

export default class extends CalculatorController {
  // Actions

  preset({ currentTarget }) {
    const input = this.element.querySelector("[data-field='ma']")
    input.value = currentTarget.dataset.ma
    this.compute({ target: input })
  }

  paint(input) {
    const result = maScaling(input)

    this.render({
      eu: this.num(result.eu, 4),
      percent: this.num(result.percent, 1),
      ma: this.num(result.ma, 3)
    })
    this.#draw(input, result)
  }

  // Private

  #draw(input, result) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    const smin = input.smin ?? 4
    const smax = input.smax ?? 20
    const { fraction } = result
    const zone = this.#zone(input.ma, smin, smax)

    diagram.dataset.state =
      fraction == null ? "empty" : fraction < 0 || fraction > 1 ? "out" : "ok"
    diagram.dataset.zone = zone
    diagram.toggleAttribute("data-broken", input.ma != null && input.ma < BREAK_BELOW)

    this.#drawTank(diagram, input, result)
    this.#drawScale(diagram, input.ma, result.ma, smin, smax)
    this.#flow(diagram, input.ma)

    const withUnit = (value) => `${this.num(value, 2)} ${diagram.dataset.unit}`
    this.label({
      "signal-min": this.num(smin, 2),
      "signal-max": this.num(smax, 2),
      "range-min": this.sig(input.rmin, 4),
      "range-max": this.sig(input.rmax, 4),
      percent: fraction == null ? this.num(null) : `${this.num(result.percent, 1)} %`,
      signal: input.ma == null ? this.num(null) : withUnit(input.ma),
      value: this.sig(result.eu, 4)
    })

    const phrases = JSON.parse(diagram.dataset.phrases)
    const complete = zone !== "empty" && (zone !== "ok" || result.eu != null)
    this.#say(diagram.querySelector("[data-say]"), phrases[complete ? zone : "empty"], {
      ma: this.num(input.ma, 2),
      percent: this.num(result.percent, 1),
      eu: this.sig(result.eu, 4)
    })

    const reverse = diagram.querySelector("[data-reverse]")
    reverse.hidden = result.ma == null
    this.#say(reverse, diagram.dataset.reversePhrase, { eu: this.sig(input.eu, 4), ma: this.num(result.ma, 3) })
    diagram.querySelector("[data-live-zero]").hidden = smin !== 4
  }

  #zone(ma, smin, smax) {
    if (ma == null || smax === smin) return "empty"
    const standard = smin === 4 && smax === 20
    if (standard && ma <= FAULT_LOW) return "fault_low"
    if (standard && ma >= FAULT_HIGH) return "fault_high"
    if (ma < Math.min(smin, smax)) return standard ? "below" : "under"
    if (ma > Math.max(smin, smax)) return standard ? "above" : "over"
    return "ok"
  }

  #drawTank(diagram, input, { fraction, ma }) {
    const level = diagram.querySelector("[data-level]")
    level.style.transform = `translateY(${(1 - clamp(fraction ?? 0, 0, 1)) * TANK_HEIGHT + (fraction > 0 ? 0 : 6)}px)`

    const span = input.rmax - input.rmin
    const share = ma == null ? null : (input.eu - input.rmin) / span
    const target = diagram.querySelector("[data-target]")
    target.toggleAttribute("data-hidden", share == null || share < 0 || share > 1)
    if (share != null) target.style.transform = `translateY(${TANK_TOP + (1 - clamp(share, 0, 1)) * TANK_HEIGHT}px)`
  }

  #drawScale(diagram, ma, targetMa, smin, smax) {
    const low = Math.min(0, smin, smax)
    const top = Math.max(smin, smax)
    const high = top <= 20 ? SCALE_END : Math.ceil(top * 1.2)
    const share = (value) => clamp((value - low) / (high - low), 0, 1)
    const scale = diagram.querySelector("[data-scale]")

    const standard = smin === 4 && smax === 20
    const from = Math.min(smin, smax)
    const edges = [ low, standard ? FAULT_LOW : low, from, top, standard ? FAULT_HIGH : high, high ]
    scale.querySelectorAll("[data-band]").forEach((band, index) => {
      band.style.flexGrow = String(share(edges[index + 1]) - share(edges[index]))
    })

    const place = (el, value) => el.style.setProperty("--at", String(share(value)))
    place(scale.querySelector("[data-tick='smin']"), smin)
    place(scale.querySelector("[data-tick='smax']"), smax)
    const zero = scale.querySelector("[data-tick='low']")
    zero.textContent = this.num(low, 2)
    zero.hidden = share(from) < 0.08

    const ghost = scale.querySelector("[data-ghost]")
    ghost.hidden = targetMa == null || targetMa < low || targetMa > high
    if (targetMa != null) place(ghost, targetMa)

    const range = scale.querySelector("input")
    range.min = String(low)
    range.max = String(high)
    range.value = String(ma ?? low)
    range.setAttribute("aria-valuetext", `${this.num(ma, 2)} ${diagram.dataset.unit}`)
  }

  // playbackRate, not animation-duration: changing the duration makes the dots jump.
  #flow(diagram, ma) {
    const current = clamp(ma ?? 0, 0, SCALE_END)
    const dots = diagram.querySelector("[data-dots]")
    dots.style.strokeWidth = `${3 + current / 6}px`
    dots.style.opacity = current < BREAK_BELOW ? "0" : "1"
    dots.getAnimations().forEach((animation) => { animation.playbackRate = current / 10 })
  }

  #say(element, phrase, values) {
    const text = phrase.replace(/%\{(\w+)\}/g, (_, name) => values[name])
    if (element.textContent !== text) element.textContent = text
  }
}
