import { Controller } from "@hotwired/stimulus"

const KEY = "typed"

// The hero's heading types itself once per browser session; CSS does the typing.
export default class extends Controller {
  static classes = [ "done" ]

  connect() {
    try {
      if (sessionStorage.getItem(KEY)) this.element.classList.add(this.doneClass)
      sessionStorage.setItem(KEY, "1")
    } catch {
      // Storage blocked — the heading just types every time.
    }
  }
}
