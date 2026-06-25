import { Controller } from "@hotwired/stimulus"

// Add / remove / reorder rows for a has_many rendered with
// accepts_nested_attributes_for. No gem — the Rails "child_index template"
// pattern plus a little native drag-and-drop. Used by the lesson resource
// (links) editor; generic enough to reuse elsewhere.
export default class extends Controller {
  static targets = ["list", "template", "item", "badge", "kind", "position", "destroy"]
  static values = { kinds: Object }

  connect() {
    this.itemTargets.forEach((item) => this.paintBadge(item))
  }

  addItem(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.uid())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    const item = this.listTarget.lastElementChild
    this.paintBadge(item)
    this.renumber()
    item.querySelector("input.input")?.focus()
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    const persisted = item.querySelector("input[name*='[id]']")
    if (persisted) {
      item.querySelector("[data-nested-form-target='destroy']").value = "1"
      item.hidden = true
    } else {
      item.remove()
    }
    this.renumber()
  }

  refreshBadge(event) {
    this.paintBadge(event.target.closest("[data-nested-form-target='item']"))
  }

  // --- drag-and-drop reorder (top = most important) ---
  dragStart(event) {
    this.dragging = event.target.closest("[data-nested-form-target='item']")
    this.dragging.classList.add("is-dragging")
  }

  dragEnd() {
    this.dragging?.classList.remove("is-dragging")
    this.dragging = null
    this.renumber()
  }

  dragOver(event) {
    if (!this.dragging) return
    event.preventDefault()
    const after = this.itemAfter(event.clientY)
    if (!after) {
      this.listTarget.appendChild(this.dragging)
    } else if (after !== this.dragging) {
      this.listTarget.insertBefore(this.dragging, after)
    }
  }

  itemAfter(y) {
    return this.itemTargets
      .filter((item) => item !== this.dragging && !item.hidden)
      .find((item) => {
        const box = item.getBoundingClientRect()
        return y < box.top + box.height / 2
      })
  }

  // --- helpers ---
  // The coloured kind badge mirrors the reader's resource badges, one hue per
  // kind. Updates live as the kind <select> changes.
  paintBadge(item) {
    const badge = item?.querySelector("[data-nested-form-target='badge']")
    const kind = item?.querySelector("[data-nested-form-target='kind']")
    if (!badge || !kind) return
    const [modifier, label] = this.kindsValue[kind.value] || ["badge--book", kind.value]
    badge.className = `badge resource-row__badge ${modifier}`
    badge.textContent = label
  }

  renumber() {
    let position = 0
    this.itemTargets.forEach((item) => {
      if (item.hidden) return
      const field = item.querySelector("[data-nested-form-target='position']")
      if (field) field.value = position++
    })
  }

  uid() {
    return `${new Date().getTime()}${Math.floor(Math.random() * 1000)}`
  }
}
