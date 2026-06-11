import { Controller } from "@hotwired/stimulus"

// Native <dialog> modal: opens on connect (one-shot messages like the
// welcome letter), closes on button, Esc (native) or backdrop click.
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
