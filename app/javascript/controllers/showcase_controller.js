import { Controller } from "@hotwired/stimulus"

const FALLBACK_LAP = 10000

// The home stage: each profession's scene plays its story once, then the next takes over.
// A slide leaves the layout while hidden, so its CSS animations restart from zero when shown.
export default class extends Controller {
  static targets = [ "slide", "tab" ]

  #index = 0
  #timer

  // Lifecycle

  connect() {
    document.addEventListener("visibilitychange", this.#onVisibilityChange)
    this.#show(0)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.#onVisibilityChange)
    clearTimeout(this.#timer)
  }

  // Actions

  select({ params: { index } }) {
    this.#show(index)
  }

  // Private

  #onVisibilityChange = () => {
    document.hidden ? clearTimeout(this.#timer) : this.#show(this.#index)
  }

  #show(index) {
    this.#index = index
    this.slideTargets.forEach(slide => slide.hidden = true)
    this.tabTargets.forEach(tab => tab.setAttribute("aria-selected", "false"))
    void this.element.offsetWidth // lets the tab's progress bar restart even on the same tab

    this.slideTargets[index].hidden = false
    this.tabTargets[index].setAttribute("aria-selected", "true")
    this.element.style.setProperty("--showcase-lap", `${this.#lap}ms`)
    this.#schedule()
  }

  #schedule() {
    clearTimeout(this.#timer)
    if (this.slideTargets.length < 2 || matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.#timer = setTimeout(() => this.#show((this.#index + 1) % this.slideTargets.length), this.#lap)
  }

  get #lap() {
    const scene = this.slideTargets[this.#index].querySelector(".scene")
    const seconds = scene && parseFloat(getComputedStyle(scene).getPropertyValue("--lap"))

    return seconds ? seconds * 1000 : FALLBACK_LAP
  }
}
