import { Controller } from "@hotwired/stimulus"

// Command palette: the header search icon, Ctrl/Cmd+K or "/" opens a native
// <dialog> with live lesson search plus quick destinations. The trigger stays
// a real link to /search, so without JS it falls back to the full page.
export default class extends Controller {
  static targets = ["dialog", "input"]

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.select()
  }

  close() {
    this.dialogTarget.close()
  }

  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  hotkey(event) {
    if (this.#commandK(event)) {
      event.preventDefault()
      this.dialogTarget.open ? this.close() : this.open()
    } else if (event.key === "/" && !this.#typing(event)) {
      event.preventDefault()
      this.open()
    }
  }

  // Private

  // "л" sits on the K key in ЙЦУКЕН, so the shortcut survives the RU layout.
  #commandK(event) {
    return (event.metaKey || event.ctrlKey) && ["k", "K", "л", "Л"].includes(event.key)
  }

  #typing(event) {
    return event.target.closest?.("input, textarea, select, [contenteditable]")
  }
}
