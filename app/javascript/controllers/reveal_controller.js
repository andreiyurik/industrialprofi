import { Controller } from "@hotwired/stimulus"

// Reliable in-page anchoring for a page whose layout settles late. The lesson
// page's "edit links" button links to #resources-editor, but a native anchor
// jump lands too high: the rich-text (Lexxy) editors above expand AFTER load and
// push the target down. When this element is the current URL anchor, we re-scroll
// to it once layout has settled and focus the first link's URL field, so the
// expert lands right in the link editor.
export default class extends Controller {
  connect() {
    if (location.hash !== `#${this.element.id}`) return

    // Two frames + a short delay clears the async editor layout shift before we
    // jump; a final pass on window load catches anything still settling.
    this.reveal = this.reveal.bind(this)
    requestAnimationFrame(() =>
      requestAnimationFrame(() => setTimeout(this.reveal, 120))
    )
    window.addEventListener("load", this.reveal, { once: true })
  }

  disconnect() {
    window.removeEventListener("load", this.reveal)
  }

  reveal() {
    this.element.scrollIntoView({ block: "start" })
    this.element.querySelector(".resource-row__url")?.focus({ preventScroll: true })
  }
}
