import { Controller } from "@hotwired/stimulus"

// Copies a URL (or any value) to the clipboard and briefly confirms: swaps
// the label to "Скопировано" and, when the host page passes a copied-class
// (data-copy-link-copied-class), toggles it on the button for icon feedback.
//
// Progressive enhancement: the copy button is rendered with `hidden`, and only
// this controller reveals it on connect — so without JS there is no dead button.
export default class extends Controller {
  static targets = ["button", "label"]
  static classes = ["copied"]
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
    if (this.hasCopiedClass) this.buttonTarget.classList.add(this.copiedClass)
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.reset(), this.durationValue)
  }

  reset() {
    this.labelTarget.textContent = this.labelValue
    if (this.hasCopiedClass) this.buttonTarget.classList.remove(this.copiedClass)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
