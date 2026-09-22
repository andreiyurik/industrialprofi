import { Controller } from "@hotwired/stimulus"

// Swaps the label to "Скопировано" and toggles the copied-class if one is passed.
// The button ships `hidden` and is revealed here, so there's no dead button without JS.
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
