import { Controller } from "@hotwired/stimulus"

// Lives on the lesson layout wrapper so the open state survives Turbo Stream
// replacements of the panel itself.
export default class extends Controller {
  static targets = ["panel"]
  static classes = ["open"]

  // Runs on load and every Turbo Stream swap; keeps the current lesson centered
  // without touching the page scroll position.
  panelTargetConnected(panel) {
    const current = panel.querySelector('[aria-current="page"]')
    if (!current) return

    const delta = current.getBoundingClientRect().top - panel.getBoundingClientRect().top
    panel.scrollTop += delta - panel.clientHeight / 2
  }

  open() {
    this.element.classList.add(this.openClass)
  }

  close() {
    this.element.classList.remove(this.openClass)
  }
}
