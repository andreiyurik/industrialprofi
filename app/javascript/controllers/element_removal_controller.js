import { Controller } from "@hotwired/stimulus"

// Removes the controller's element after a delay. Used by shared/_flash.html.erb.
// Pattern adapted from basecamp/fizzy.
export default class extends Controller {
  static values = { delay: { type: Number, default: 0 } }

  connect() {
    if (this.delayValue > 0) {
      this.timeout = setTimeout(() => this.remove(), this.delayValue)
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  remove() {
    this.element.remove()
  }
}
