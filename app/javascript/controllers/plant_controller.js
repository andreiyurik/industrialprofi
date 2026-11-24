import { Controller } from "@hotwired/stimulus"

const KEYS = [ "main", "control", "drive", "valve" ]
const STEPS = [ ...KEYS, "start" ]
const LESSONS = { no_power: "power", no_drive: "power", no_control: "control", dry: "control", dry_running: "control" }
const TRIP_FLASH = 2400
const SHARED_FLASH = 2000

// The home page's drawing as a game: the visitor powers the installation up and starts the pump.
// State lives in data attributes on the figure — blueprint.css draws every one of them.
export default class extends Controller {
  static targets = [ "status", "step", "switch", "done", "lesson", "share" ]
  static values = { messages: Object, share: String, shared: String, url: String }

  #state = { main: false, drive: false, control: false, valve: false, run: false }
  #startedAt
  #attempts = 0
  #result
  #tripTimer
  #shareTimer

  // Lifecycle

  connect() {
    this.element.dataset.plant = ""
    this.element.dataset.fresh = ""
    this.#render("idle")
  }

  disconnect() {
    clearTimeout(this.#tripTimer)
    clearTimeout(this.#shareTimer)
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
    this.#attempts++

    const blocker = this.#blocker
    if (blocker === "dry") return this.#trip("dry")
    if (blocker) return this.#render(blocker)

    this.#state.run = true
    this.#result = { seconds: Math.max(1, Math.round((Date.now() - this.#startedAt) / 1000)), attempt: this.#attempts }
    this.#render(this.#attempts === 1 ? "success_first" : "success_retry", this.#result)
    this.doneTarget.scrollIntoView({ block: "nearest", behavior: "smooth" })
    window.reachGoal?.("plant_launched")
  }

  reset() {
    KEYS.forEach(key => this.#state[key] = false)
    this.#state.run = false
    this.#startedAt = null
    this.#attempts = 0
    this.#render("idle")
  }

  async share() {
    const text = this.#fill(this.shareValue, this.#result)

    try {
      if (navigator.share) {
        await navigator.share({ text, url: this.urlValue })
      } else {
        await navigator.clipboard.writeText(`${text} ${this.urlValue}`)
        this.#confirmShared()
      }
      window.reachGoal?.("link_copied")
    } catch {
      // Share sheet dismissed or clipboard unavailable — nothing to tell the visitor.
    }
  }

  // Private

  get #powered() { return this.#state.main }
  get #driveLive() { return this.#powered && this.#state.drive }
  get #controlLive() { return this.#powered && this.#state.control }
  get #canRun() { return this.#driveLive && this.#controlLive && this.#state.valve }
  get #next() { return this.#state.run ? null : KEYS.find(key => !this.#state[key]) || "start" }

  get #blocker() {
    if (!this.#powered) return "no_power"
    if (!this.#controlLive) return "no_control"
    if (!this.#driveLive) return "no_drive"
    if (!this.#state.valve) return "dry"
  }

  #begin() {
    delete this.element.dataset.fresh
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
    this.#render(message)
  }

  #render(message, values = {}) {
    const flags = { ...this.#state, driveLive: this.#driveLive, controlLive: this.#controlLive }
    Object.entries(flags).forEach(([ flag, on ]) => this.element.toggleAttribute(`data-${this.#dasherize(flag)}`, on))

    const next = this.#next
    if (next) this.element.dataset.next = next; else delete this.element.dataset.next

    this.switchTargets.forEach(part => part.setAttribute("aria-pressed", this.#state[part.dataset.plantKeyParam]))
    this.stepTarget.hidden = !next
    this.stepTarget.textContent = `${STEPS.indexOf(next) + 1}/${STEPS.length}`
    this.statusTarget.textContent = this.#fill(this.messagesValue[message], values)
    this.statusTarget.parentElement.dataset.tone = message.startsWith("dry") ? "alarm" : (this.#state.run ? "ok" : "")
    this.lessonTargets.forEach(link => link.hidden = link.dataset.slot !== LESSONS[message])
    this.doneTarget.hidden = !this.#state.run
  }

  #confirmShared() {
    const label = this.shareTarget.textContent
    this.shareTarget.textContent = this.sharedValue
    clearTimeout(this.#shareTimer)
    this.#shareTimer = setTimeout(() => this.shareTarget.textContent = label, SHARED_FLASH)
  }

  #fill(text = "", values = {}) {
    return text.replace(/%\{(\w+)\}/g, (_, name) => values[name] ?? "")
  }

  #dasherize(name) {
    return name.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`)
  }
}
