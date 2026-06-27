import { Controller } from "@hotwired/stimulus"

// Copies a fixed string (its `text` value) to the clipboard and briefly swaps
// the icon to a check. Lets an author grab a `[!СОВЕТ]` marker from the
// cheatsheet with one click instead of typing it by hand. Generic — any
// "copy this snippet" button can reuse it.
export default class extends Controller {
  static values = { text: String, duration: { type: Number, default: 1500 } }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.classList.add("is-copied")
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => this.element.classList.remove("is-copied"), this.durationValue)
    } catch (e) {
      // Clipboard unavailable (e.g. insecure context) — fail quietly.
    }
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
