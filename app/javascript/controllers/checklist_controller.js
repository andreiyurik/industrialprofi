import { Controller } from "@hotwired/stimulus"

// Fizzy's toggle_class_controller#checkAll/checkNone: «Все · Ничего» plus a live count.
export default class extends Controller {
  static targets = [ "box", "count" ]
  static values = { format: String }

  // Lifecycle

  connect() {
    this.count()
  }

  // Actions

  // preventDefault: the buttons live inside a <summary>, which would fold the chapter otherwise.
  all(event) {
    event.preventDefault()
    this.#check(event.target, true)
  }

  none(event) {
    event.preventDefault()
    this.#check(event.target, false)
  }

  count() {
    this.countTargets.forEach(counter => {
      const boxes = this.#boxesAround(counter)
      const chosen = boxes.filter(box => box.checked).length
      counter.textContent = this.formatValue.replace("%{count}", chosen).replace("%{total}", boxes.length)
    })
  }

  // Private

  #check(origin, checked) {
    this.#boxesAround(origin).forEach(box => box.checked = checked)
    this.count()
  }

  // A button/counter inside a chapter acts on that chapter; one outside acts on the whole list.
  #boxesAround(element) {
    const scope = element.closest("[data-checklist-group]") || this.element
    return [ ...scope.querySelectorAll("[data-checklist-target~='box']") ]
  }
}
