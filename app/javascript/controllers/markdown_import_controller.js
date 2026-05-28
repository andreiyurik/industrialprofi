import { Controller } from "@hotwired/stimulus"

// Lets a Markdown-loving admin paste Markdown into a box, convert it to HTML
// (via the same Kramdown endpoint the live preview uses), and drop the result
// into the lexxy rich-text editor. lexxy stays the source of truth.
export default class extends Controller {
  static targets = ["editor", "source"]
  static values = { url: String }

  async convert() {
    const markdown = this.sourceTarget.value.trim()
    if (!markdown) return

    const html = await this.toHtml(markdown)
    if (html == null) return

    const editor = this.editorTarget
    const hasContent = editor.toString().trim().length > 0
    editor.value = hasContent ? `${editor.value}${html}` : html

    this.sourceTarget.value = ""
  }

  async toHtml(markdown) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ text: markdown })
      })

      if (!response.ok) return null
      return (await response.json()).html
    } catch (e) {
      return null
    }
  }
}
