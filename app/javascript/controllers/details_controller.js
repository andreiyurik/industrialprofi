import { Controller } from "@hotwired/stimulus"

// Light dismiss for a <details> disclosure (Fizzy's details_controller):
// wire `click@document->details#closeOnClickOutside` and it closes like a
// menu should — native toggle behavior stays untouched.
export default class extends Controller {
  static targets = ["details"]

  close() {
    this.detailsTarget.removeAttribute("open")
  }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }
}
