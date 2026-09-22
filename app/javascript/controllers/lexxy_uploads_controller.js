import { Controller } from "@hotwired/stimulus"

// lexxy:file-accept is cancelable; preventing it drops the file. The server
// (Admin::UploadsController) enforces the same byte cap — this is instant feedback only.
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
