import { Controller } from "@hotwired/stimulus"
import { nextFrame, delay } from "helpers/timing_helpers"

// A native anchor jump to #resources-editor lands too high: rich-text (Lexxy)
// editors above expand AFTER load and push the target down. Re-scroll once layout
// has settled and focus the first link's URL field.
export default class extends Controller {
  connect() {
    if (location.hash !== `#${this.element.id}`) return

    this.reveal = this.reveal.bind(this)
    this.settleThenReveal()
    // A final pass on window load catches anything still settling.
    window.addEventListener("load", this.reveal, { once: true })
  }

  // Two frames + a short delay clears the async editor layout shift before we jump.
  async settleThenReveal() {
    await nextFrame()
    await nextFrame()
    await delay(120)
    this.reveal()
  }

  disconnect() {
    window.removeEventListener("load", this.reveal)
  }

  reveal() {
    this.element.scrollIntoView({ block: "start" })
    this.element.querySelector(".resource-row__url")?.focus({ preventScroll: true })
  }
}
