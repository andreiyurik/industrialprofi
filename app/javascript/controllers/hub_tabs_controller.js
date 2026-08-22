import { Controller } from "@hotwired/stimulus"

// The profession hub's tab row scrolls sideways on phones; on load, slide the
// current tab into the middle of the row — horizontally only, so the page
// itself never jumps. Nothing else: the tabs are plain links.
export default class extends Controller {
  connect() {
    const current = this.element.querySelector("[aria-current]")
    if (!current) return
    this.element.scrollLeft = current.offsetLeft - (this.element.clientWidth - current.offsetWidth) / 2
  }
}
