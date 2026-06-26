import { Controller } from "@hotwired/stimulus"

// Inline rename: double-click a title to edit it in place; Enter (form submit)
// PATCHes a thin endpoint and the new text simply stays. Escape cancels; on a
// failed request we revert and flash the title red. Used in the builder for
// lesson/course titles and section headings — the heading also mirrors the new
// name into its data-stage, which the reorder payload reads.
//
// While editing we disable the nearest draggable ancestor so selecting text in
// the input doesn't start a drag.
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
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
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
