import { Controller } from "@hotwired/stimulus"

// Rejects an oversized image before it uploads, with a readable message.
// Lexxy's `lexxy:file-accept` is cancelable; preventing it drops the file.
// Type is already gated by the editor's `permitted-attachment-types`, and the
// server (Admin::UploadsController) enforces the same byte cap — this is just
// instant feedback so an author isn't left watching a doomed upload.
export default class extends Controller {
  static values = { maxBytes: Number, message: String }

  connect() {
    this.element.addEventListener("lexxy:file-accept", this.#check)
  }

  disconnect() {
    this.element.removeEventListener("lexxy:file-accept", this.#check)
  }

  #check = (event) => {
    if (event.detail.file.size > this.maxBytesValue) {
      event.preventDefault()
      window.alert(this.messageValue)
    }
  }
}
