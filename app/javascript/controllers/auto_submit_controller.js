import { Controller } from "@hotwired/stimulus"

// Submits the form as soon as a control changes — turns a <select> into an
// instant filter, no "apply" button. Progressive enhancement: a <noscript>
// submit button covers the no-JS case, so the filter works either way.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
