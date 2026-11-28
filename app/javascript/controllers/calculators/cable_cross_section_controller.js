// @ts-check
import CalculatorController from "controllers/calculator_controller"
import { cableCrossSection } from "calculators/math/electrical"

// Дублирует размеры из diagrams/_cable-cross-section.html.erb.
const STEPS = 5
const PLOT_HEIGHT = 128
const MAX_RADIUS = 46

export default class extends CalculatorController {
  #pinned = null

  // Actions

  compute(event) {
    if (event?.target?.dataset?.rangeFor === "p") this.#fill("i", "")
    super.compute(event)
  }

  preset(event) {
    const { power, phase } = event.currentTarget.dataset
    this.#fill("p", this.num(Number(power)))
    this.#fill("phase", phase)
    this.#fill("i", "")
    this.#fill("u", "")
    this.#pinned = null
    this.compute(event)
  }

  pin(event) {
    const size = Number(event.currentTarget.dataset.size)
    this.#pinned = size === this.#pinned || size === this.recommended ? null : size
    this.paint(this.read())
  }

  paint(input) {
    const result = cableCrossSection(input, this.normsValue)

    this.render({
      current: this.num(result.current, 1),
      apparent: this.num(result.apparent, 2),
      section: this.#section(result),
      allowed: this.num(result.allowed, 0),
      breaker: this.num(result.breaker, 0)
    })
    this.recommended = result.section
    if (result.current == null || !result.rows.some(([size]) => size === this.#pinned)) this.#pinned = null
    this.#drawLadder(result)
    this.#drawScene(input, result)
  }

  // Private

  // Ток выше таблицы — сечения нет; «больше самого толстого» честнее прочерка.
  #section(result) {
    if (result.index != null || result.current == null) return this.num(result.section, 1)
    return `> ${this.num(result.rows.at(-1)[0], 1)}`
  }

  #fill(field, value) {
    const input = this.element.querySelector(`[data-field="${field}"]`)
    if (input) input.value = value
  }

  #drawScene(input, { current, rows, index, section }) {
    const figure = this.element.querySelector(".cable-viz")
    if (!figure) return

    const texts = JSON.parse(figure.dataset.texts)
    const say = (key, values = {}) => texts[key].replace(/%\{(\w+)\}/g, (_, name) => values[name])
    const live = current != null && current > 0
    // Без подходящего сечения показываем самое толстое — и то, что его мало.
    const row = rows.find(([size]) => size === this.#pinned) ?? rows[index ?? rows.length - 1]
    const [size, amps] = row ?? [0, 0]
    const state = !live ? "empty" : current > amps ? "over" : "fits"
    const preset = this.#matchPreset(input)

    figure.dataset.state = state
    figure.dataset.load = preset ?? "generic"
    figure.dataset.material = input.material
    figure.dataset.compare = String(live && index != null && size !== section)

    // Степень сглаживает разброс 1,5–120 мм²: в точном масштабе тонкие жилы неразличимы.
    const radius = (mm2) => (rows.length ? MAX_RADIUS * (mm2 / rows.at(-1)[0]) ** 0.35 : 0)
    figure.style.setProperty("--core", `${live ? 3 + radius(size) * 0.4 : 8}px`)
    figure.style.setProperty("--flow", `${live ? Math.min(2, Math.max(0.15, 12 / current)) : 1}s`)
    figure.style.setProperty("--share", String(live ? Math.min(1, current / amps) : 0))
    this.#radius(figure, ".cable-viz__disc", live ? radius(size) : 0)
    this.#radius(figure, ".cable-viz__ghost", live && section != null ? radius(section) : 0)

    const values = {
      current: this.num(current, state === "over" && this.num(current, 1) === this.num(amps, 1) ? 2 : 1),
      size: this.num(size, 1),
      amps: this.num(amps, 0),
      best: this.num(section, 1)
    }
    this.label({
      source: say(`source_${input.phase}`, { volts: this.num(input.u ?? (input.phase === "1" ? 220 : 380), 0) }),
      load: input.i != null ? say("given") : input.p != null ? say("power", { power: this.num(input.p, 2) }) : "",
      viewed: live ? say("size", values) : "",
      flowing: live ? say("flowing", values) : "",
      limit: live ? say("limit", values) : ""
    })

    let key = "empty"
    if (live && index == null) key = "none"
    else if (state === "over") key = "small"
    else if (live) key = size === section ? "pick" : "larger"
    const sentence = say(key, values)
    const slot = figure.querySelector("[data-say]")
    if (slot && slot.textContent !== sentence) slot.textContent = sentence

    this.element.querySelectorAll("[data-preset]").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.preset === preset))
    })
  }

  #matchPreset({ p, i, phase }) {
    if (i != null) return null
    const buttons = [ ...this.element.querySelectorAll("[data-preset]") ]
    return buttons.find((button) => Number(button.dataset.power) === p && button.dataset.phase === phase)?.dataset.preset
  }

  #radius(figure, selector, value) {
    figure.querySelector(selector)?.style.setProperty("r", `${value}px`)
  }

  #drawLadder({ rows, index, current }) {
    const diagram = this.element.querySelector("[data-diagram]")
    if (!diagram) return

    diagram.dataset.state = current == null ? "empty" : "ok"

    const start = current == null ? 0 : this.#windowStart(rows.length, index)
    const visible = rows.slice(start, start + STEPS)
    const ceiling = Math.max(...visible.map(([, amps]) => amps))
    const viewed = this.#pinned ?? rows[index]?.[0]

    const amperes = JSON.parse(this.element.querySelector(".cable-viz").dataset.texts).amps
    const withUnit = (value, digits) => amperes.replace("%{amps}", this.num(value, digits))
    const figures = { current: current == null ? this.num(null) : withUnit(current, 1) }
    for (let slot = 0; slot < STEPS; slot++) {
      const step = diagram.querySelector(`[data-step="${slot}"]`)
      if (!step) continue

      const row = visible[slot]
      step.dataset.state = row ? (start + slot === index ? "pick" : "plain") : "off"
      if (!row) continue

      step.dataset.size = String(row[0])
      step.dataset.fits = String(current == null || row[1] >= current)
      step.setAttribute("aria-pressed", String(row[0] === viewed))
      const bar = step.querySelector(".section-ladder__bar")
      if (bar) bar.style.transform = `scaleY(${row[1] / ceiling})`
      figures[`section-${slot}`] = this.num(row[0], 1)
      figures[`amps-${slot}`] = withUnit(row[1], 0)
    }
    this.label(figures)

    const line = diagram.querySelector("[data-current]")
    const share = current == null ? 0 : Math.max(0, Math.min(1, current / ceiling))
    if (line) line.style.transform = `translateY(${-share * PLOT_HEIGHT}px)`
  }

  // Держит ответ третьей ступенью; без ответа показывает конец таблицы.
  #windowStart(count, index) {
    const last = Math.max(0, count - STEPS)
    if (index == null) return last
    return Math.min(last, Math.max(0, index - 2))
  }
}
