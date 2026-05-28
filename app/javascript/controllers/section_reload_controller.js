import { Controller } from "@hotwired/stimulus"

// Reload the suggestion form with the chosen section so the editor
// prepopulates with that section's current content
// (see LessonSuggestionsController#new / #prepopulate_rich_body).
export default class extends Controller {
  static values = { url: String }

  navigate(event) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("section", event.target.value)

    if (window.Turbo) {
      window.Turbo.visit(url.toString())
    } else {
      window.location.assign(url.toString())
    }
  }
}
