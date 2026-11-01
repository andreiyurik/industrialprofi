import { Controller } from "@hotwired/stimulus"

// window.reachGoal exists only where the Metrika counter is configured.
export default class extends Controller {
  static values = { name: String, onConnect: Boolean }

  // Removing the one-shot marker keeps a Turbo-restored snapshot from counting it twice.
  connect() {
    if (this.onConnectValue) {
      this.reach()
      this.element.remove()
    }
  }

  reach() {
    window.reachGoal?.(this.nameValue)
  }
}
