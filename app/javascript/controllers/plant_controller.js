import { Controller } from "@hotwired/stimulus"

const KEYS = [ "main", "drive", "control", "valve" ]
const TRIP_FLASH = 2400

// The home page's drawing as a control desk: the visitor powers the installation up and starts
// the pump. State lives in data attributes on the figure — blueprint.css draws every one of them.
export default class extends Controller {
  static targets = [ "panel", "status", "switch", "done" ]
  static values = { messages: Object }

  #state = { main: false, drive: false, control: false, valve: false, run: false }
  #startedAt
  #tripTimer

  // Lifecycle

  connect() {
    this.panelTarget.hidden = false
    this.element.dataset.plant = ""
    this.#render("idle")
  }

  disconnect() {
    clearTimeout(this.#tripTimer)
  }

  // Actions

  toggle({ params: { key } }) {
    this.#begin()
    this.#state[key] = !this.#state[key]

    if (this.#state.run && !this.#state.valve) return this.#trip("dry_running")
    if (this.#state.run && !this.#canRun) {
      this.#state.run = false
      return this.#render("stopped")
    }

    this.#render(this.#messageFor(key))
  }

  start() {
    this.#begin()
    if (this.#state.run) return

    const blocker = this.#blocker
    if (blocker === "dry") return this.#trip("dry")
    if (blocker) return this.#render(blocker)

    this.#state.run = true
    const seconds = Math.max(1, Math.round((Date.now() - this.#startedAt) / 1000))
    this.#render("success", { seconds })
    this.doneTarget.hidden = false
    window.reachGoal?.("plant_launched")
  }

  reset() {
    KEYS.forEach(key => this.#state[key] = false)
    this.#state.run = false
    this.#startedAt = null
    this.doneTarget.hidden = true
    this.#render("idle")
  }

  // Private

  get #powered() { return this.#state.main }
  get #driveLive() { return this.#powered && this.#state.drive }
  get #controlLive() { return this.#powered && this.#state.control }
  get #canRun() { return this.#driveLive && this.#controlLive && this.#state.valve }

  get #blocker() {
    if (!this.#powered) return "no_power"
    if (!this.#controlLive) return "no_control"
    if (!this.#driveLive) return "no_drive"
    if (!this.#state.valve) return "dry"
  }

  #begin() {
    if (this.#startedAt) return
    this.#startedAt = Date.now()
    window.reachGoal?.("plant_started")
  }

  #messageFor(key) {
    const on = this.#state[key]
    if (key === "valve") return on ? "valve_open" : "valve_closed"
    if (key === "main") return on ? "main_on" : "main_off"
    if (!this.#powered) return on ? "dead_on" : "dead_off"

    return `${key}_${on ? "on" : "off"}`
  }

  #trip(message) {
    this.#state.run = false
    this.element.dataset.trip = ""
    clearTimeout(this.#tripTimer)
    this.#tripTimer = setTimeout(() => delete this.element.dataset.trip, TRIP_FLASH)
    this.doneTarget.hidden = true
    this.#render(message)
  }

  #render(message, values = {}) {
    const flags = { ...this.#state, driveLive: this.#driveLive, controlLive: this.#controlLive }
    Object.entries(flags).forEach(([ flag, on ]) => this.element.toggleAttribute(`data-${this.#dasherize(flag)}`, on))

    this.switchTargets.forEach(button => button.setAttribute("aria-pressed", this.#state[button.dataset.plantKeyParam]))
    this.statusTarget.textContent = (this.messagesValue[message] || "").replace("%{seconds}", values.seconds)
    this.statusTarget.dataset.tone = message.startsWith("dry") ? "alarm" : (message === "success" ? "ok" : "")
  }

  #dasherize(name) {
    return name.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`)
  }
}
