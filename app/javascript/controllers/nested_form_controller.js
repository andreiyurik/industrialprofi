import { Controller } from "@hotwired/stimulus"
import { elementAfter } from "helpers/dom_helpers"

// No gem — Rails "child_index template" plus native drag-and-drop.
export default class extends Controller {
  static targets = ["list", "template", "item", "badge", "kind", "position", "destroy"]
  static values = { kinds: Object, templateId: String, defaults: Object }

  #dragging = null

  // Lifecycle

  connect() {
    this.itemTargets.forEach((item) => this.#paintBadge(item))
  }

  // Actions

  addItem(event) {
    event.preventDefault()
    const html = this.#template.innerHTML.replace(/NEW_RECORD/g, this.#uid())
    this.listTarget.insertAdjacentHTML("beforeend", html)
    const item = this.listTarget.lastElementChild
    this.#applyDefaults(item)
    this.#paintBadge(item)
    this.#renumber()
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
    this.#renumber()
  }

  refreshBadge(event) {
    this.#paintBadge(event.target.closest("[data-nested-form-target='item']"))
  }

  dragStart(event) {
    this.#dragging = event.target.closest("[data-nested-form-target='item']")
    this.#dragging.classList.add("is-dragging")
  }

  dragEnd() {
    this.#dragging?.classList.remove("is-dragging")
    this.#dragging = null
    this.#renumber()
  }

  dragOver(event) {
    if (!this.#dragging) return
    event.preventDefault()
    const candidates = this.itemTargets.filter((item) => item !== this.#dragging && !item.hidden)
    const after = elementAfter(candidates, event.clientY)
    if (!after) {
      this.listTarget.appendChild(this.#dragging)
    } else if (after !== this.#dragging) {
      this.listTarget.insertBefore(this.#dragging, after)
    }
  }

  // Private

  // Editors that repeat down a page share one blank row instead of a copy each.
  get #template() {
    return this.hasTemplateTarget ? this.templateTarget : document.getElementById(this.templateIdValue)
  }

  // What a shared blank row cannot know: which lesson this box hangs under.
  #applyDefaults(item) {
    Object.entries(this.defaultsValue).forEach(([name, value]) => {
      const field = item.querySelector(`[name$="[${name}]"]`)
      if (field) field.value = value
    })
  }

  // The dot borrows the badge hue via currentColor; updates live as the kind <select> changes.
  #paintBadge(item) {
    const badge = item?.querySelector("[data-nested-form-target='badge']")
    const kind = item?.querySelector("[data-nested-form-target='kind']")
    if (!badge || !kind) return
    const [modifier, label] = this.kindsValue[kind.value] || ["badge--book", kind.value]
    badge.className = `resource-row__dot ${modifier}`
    badge.title = label
  }

  #renumber() {
    let position = 0
    this.itemTargets.forEach((item) => {
      if (item.hidden) return
      const field = item.querySelector("[data-nested-form-target='position']")
      if (field) field.value = position++
    })
  }

  #uid() {
    return `${new Date().getTime()}${Math.floor(Math.random() * 1000)}`
  }
}
