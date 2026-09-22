import { Controller } from "@hotwired/stimulus"
import { rafThrottle } from "helpers/timing_helpers"

// Position-based, not direction-based: hides past the header's own height and stays
// hidden until scrolled back to the top. Pure CSS transform moves it (header.css).
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
    const threshold = this.element.offsetHeight || 64
    this.element.classList.toggle(this.hiddenClass, window.scrollY > threshold)
  }
}
