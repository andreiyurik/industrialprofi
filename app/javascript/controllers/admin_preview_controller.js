import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  preview(event) {
    const input = event.target
    const section = input.closest("[data-admin-preview-target='section']")
    const output = section.querySelector("[data-admin-preview-target='output']")

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fetchPreview(input.value, output)
    }, 300)
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
