import { Controller } from "@hotwired/stimulus"

// Reading mode: strips the page chrome (header, both rails, breadcrumbs) so
// only the lesson text remains, and — Writebook-style — takes the browser
// fullscreen on top (best effort: silently skipped where the Fullscreen API
// is unavailable, e.g. iPhone Safari). The choice lives in a cookie, so the
// server renders every next lesson already stripped — no flash of chrome.
// Esc leaves the mode (and fullscreen with it).
//
// Progressive enhancement: the toggle button is rendered `hidden` and revealed
// here on connect — without JS there is no dead button.
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

  // Fullscreen is page state, not preference: it survives Turbo visits to the
  // next lesson by itself and is NOT re-requested from the cookie on load —
  // browsers only allow the request from a user gesture anyway.
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
