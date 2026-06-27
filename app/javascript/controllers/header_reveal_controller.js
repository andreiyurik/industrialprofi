import { Controller } from "@hotwired/stimulus"
import { rafThrottle } from "helpers/timing_helpers"

// Auto-hiding header (TOP-style): the sticky header is shown only near the very
// top of the page. Once the reader scrolls past the header's own height it
// slides up out of view and STAYS hidden — it returns only when scrolled back
// to the top, NOT on an upward scroll. Position-based, not direction-based.
//
// Pure CSS transform does the moving (see header.css); this controller only
// toggles the class, rAF-throttled so scroll stays smooth.
export default class extends Controller {
  static classes = ["hidden"]

  connect() {
    this.onScroll = rafThrottle(() => this.update())
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.update() // set the right state if the page loads already scrolled
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    this.onScroll.cancel()
  }

  update() {
    // Threshold = the header's own height, so it hides the moment it scrolls
    // off and reappears only once you're back within its height of the top.
    const threshold = this.element.offsetHeight || 64
    this.element.classList.toggle(this.hiddenClass, window.scrollY > threshold)
  }
}
