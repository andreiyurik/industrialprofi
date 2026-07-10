import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

// Submits the form as soon as a control changes — turns a <select> into an
// instant filter, no "apply" button. Progressive enhancement: a <noscript>
// submit button covers the no-JS case, so the filter works either way.
// Set debounceValue (ms) for text inputs — live search submits once the
// user pauses, not on every keystroke.
export default class extends Controller {
  static values = { debounce: { type: Number, default: 0 } }

  initialize() {
    if (this.debounceValue > 0) this.submit = debounce(this.submit.bind(this), this.debounceValue)
  }

  submit() {
    this.element.requestSubmit()
  }
}
