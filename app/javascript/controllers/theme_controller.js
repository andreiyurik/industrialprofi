import { Controller } from "@hotwired/stimulus"

// Ships hidden: without JS the head script can't run, so a switch would do nothing.
export default class extends Controller {
  static targets = ["option"]

  connect() {
    this.sync()
    this.element.hidden = false
  }

  select({ target: { value } }) {
    try { localStorage.setItem("theme", value) } catch {}
    const apply = () => window.dispatchEvent(new Event("theme:change"))
    const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (!document.startViewTransition || still) return apply()

    const transition = document.startViewTransition(apply)
    transition.finished.catch(() => {})
  }

  sync() {
    const stored = this.#stored
    this.optionTargets.forEach((option) => (option.checked = option.value === stored))
  }

  get #stored() {
    let value
    try { value = localStorage.getItem("theme") } catch {}
    return value === "light" || value === "dark" ? value : "auto"
  }
}
