import { Controller } from "@hotwired/stimulus"

// Copies the lesson's canonical URL to the clipboard and briefly swaps the
// button label to confirm ("Скопировано"), then restores it.
//
// Progressive enhancement: the copy button is rendered with `hidden`, and only
// this controller reveals it on connect — so without JS there is no dead button.
export default class extends Controller {
  static targets = ["button", "label"]
  static values = {
    url: String,
    label: String,
    copied: String,
    duration: { type: Number, default: 2000 }
  }

  connect() {
    this.buttonTarget.hidden = false
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.confirm()
    } catch (e) {
      // Clipboard unavailable (e.g. insecure context) — fail quietly.
    }
  }

  confirm() {
    this.labelTarget.textContent = this.copiedValue
    this.buttonTarget.classList.add("lesson__copy--copied")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.reset(), this.durationValue)
  }

  reset() {
    this.labelTarget.textContent = this.labelValue
    this.buttonTarget.classList.remove("lesson__copy--copied")
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
