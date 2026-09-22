import { Controller } from "@hotwired/stimulus"
import { csrfToken } from "helpers/http_helpers"

// Enter PATCHes and the text stays; Escape/a failed request reverts. mirrorAttr
// also updates data-stage, which the reorder payload reads. The nearest draggable
// ancestor is disabled while editing so text selection doesn't start a drag.
export default class extends Controller {
  static targets = ["display", "form", "input"]
  static values = {
    url: String,
    method: { type: String, default: "PATCH" },
    mirrorAttr: String,
    extra: Object
  }

  start() {
    this.original = this.displayTarget.textContent.trim()
    this.inputTarget.value = this.original
    this.formTarget.hidden = false
    this.displayTarget.hidden = true
    this.draggable = this.element.closest("[draggable='true']")
    if (this.draggable) this.draggable.draggable = false
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  cancel() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
    if (this.draggable) this.draggable.draggable = true
  }

  keydown(event) {
    if (event.key === "Escape") this.cancel()
  }

  save(event) {
    event.preventDefault()
    const value = this.inputTarget.value.trim()
    if (!value || value === this.original) return this.cancel()

    this.apply(value)
    this.cancel()

    fetch(this.urlValue, {
      method: this.methodValue,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken()
      },
      body: JSON.stringify({ value, from: this.original, ...this.extraValue })
    })
      .then((response) => { if (!response.ok) throw new Error(response.status) })
      .catch(() => {
        this.apply(this.original)
        this.displayTarget.classList.add("is-error")
        setTimeout(() => this.displayTarget.classList.remove("is-error"), 1200)
      })
  }

  apply(value) {
    this.displayTarget.textContent = value
    if (this.hasMirrorAttrValue) this.element.setAttribute(this.mirrorAttrValue, value)
  }
}
