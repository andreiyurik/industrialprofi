import { Controller } from "@hotwired/stimulus"

// Copies a fenced code block to the clipboard and briefly swaps the button's
// icon to a check to confirm. Progressive enhancement: the button ships
// `hidden` and only this controller reveals it on connect — so without JS there
// is no dead button, just the code.
export default class extends Controller {
  static targets = ["button"]
  static values = { duration: { type: Number, default: 2000 } }

  connect() {
    this.buttonTarget.hidden = false
  }

  async copy() {
    const code = this.element.querySelector("pre code")
    if (!code) return

    try {
      await navigator.clipboard.writeText(code.textContent)
      this.confirm()
    } catch (e) {
      // Clipboard unavailable (e.g. insecure context) — fail quietly.
    }
  }

  confirm() {
    this.buttonTarget.classList.add("code-copy--copied")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonTarget.classList.remove("code-copy--copied")
    }, this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
