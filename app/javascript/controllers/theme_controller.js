import { Controller } from "@hotwired/stimulus"

// Ships hidden: without JS the head script can't run, so a switch would do nothing.
export default class extends Controller {
  static targets = ["option"]

  connect() {
    const stored = this.#stored
    this.optionTargets.forEach((option) => (option.checked = option.value === stored))
    this.element.hidden = false
  }

  select({ target: { value } }) {
    try { localStorage.setItem("theme", value) } catch {}
    window.dispatchEvent(new Event("theme:change"))
  }

  get #stored() {
    try { return localStorage.getItem("theme") || "auto" } catch { return "auto" }
  }
}
