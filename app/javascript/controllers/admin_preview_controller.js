import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { url: String }

  connect() {
    this.debouncedFetch = debounce((text, output) => this.fetchPreview(text, output), 300)
  }

  preview(event) {
    const input = event.target
    const section = input.closest("[data-admin-preview-target='section']")
    const output = section.querySelector("[data-admin-preview-target='output']")

    this.debouncedFetch(input.value, output)
  }

  async fetchPreview(text, output) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ text })
      })

      if (response.ok) {
        const data = await response.json()
        output.innerHTML = data.html
      }
    } catch (e) {
      // silently fail on network error
    }
  }
}
