import { Controller } from "@hotwired/stimulus"

// Cookie-backed so the server renders the next lesson already stripped — no flash
// of chrome. The toggle button ships `hidden`, revealed here so there's no dead
// button without JS.
export default class extends Controller {
  static targets = ["toggle"]
  static classes = ["active"]

  connect() {
    this.toggleTargets.forEach((button) => (button.hidden = false))
  }

  toggle() {
    const on = this.element.classList.toggle(this.activeClass)
    this.persist(on)
    if (on) {
      this.enterFullscreen()
    } else {
      this.leaveFullscreen()
    }
  }

  exit() {
    this.element.classList.remove(this.activeClass)
    this.persist(false)
    this.leaveFullscreen()
  }

  // Fullscreen is page state, not preference — it survives Turbo visits by itself
  // and isn't re-requested from the cookie (browsers require a user gesture anyway).
  enterFullscreen() {
    if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().catch(() => {})
    }
  }

  leaveFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen()
    }
  }

  persist(on) {
    document.cookie = on
      ? "reading_mode=1; path=/; max-age=31536000; samesite=lax"
      : "reading_mode=; path=/; max-age=0; samesite=lax"
  }
}
