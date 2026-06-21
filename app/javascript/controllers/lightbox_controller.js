import { Controller } from "@hotwired/stimulus"

const ZOOM_ICON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607ZM10.5 7.5v6m3-3h-6"/></svg>`
const CLOSE_ICON = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/></svg>`

// Click a lesson figure (or its zoom button) to view the image full-screen in a
// native <dialog>; click the image again to toggle between fit-to-screen and
// full resolution — diagrams carry fine text that needs a close look on phone
// and desktop alike. Progressive enhancement: with no JS the images still render
// inline, just without the zoom affordance.
export default class extends Controller {
  connect() {
    this.element.querySelectorAll(".prose-figure").forEach((figure) => {
      if (figure.querySelector(".prose-figure__zoom")) return
      const button = document.createElement("button")
      button.type = "button"
      button.className = "prose-figure__zoom"
      button.setAttribute("aria-label", "Увеличить изображение")
      button.innerHTML = ZOOM_ICON
      figure.appendChild(button)
    })

    this.onClick = this.onClick.bind(this)
    this.element.addEventListener("click", this.onClick)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
    this.dialog?.remove()
    this.dialog = null
  }

  onClick(event) {
    const trigger = event.target.closest(".prose-figure__zoom, .prose img")
    if (!trigger) return

    const figure = trigger.closest(".prose-figure, figure")
    const image = trigger.tagName === "IMG" ? trigger : figure?.querySelector("img")
    if (image) this.open(image)
  }

  open(image) {
    const dialog = this.dialog || this.buildDialog()
    const full = dialog.querySelector(".lightbox__img")
    full.src = image.currentSrc || image.src
    full.alt = image.alt || ""
    dialog.classList.remove("lightbox--zoomed")
    dialog.showModal()
  }

  buildDialog() {
    const dialog = document.createElement("dialog")
    dialog.className = "lightbox"
    dialog.innerHTML = `
      <button type="button" class="lightbox__close" aria-label="Закрыть">${CLOSE_ICON}</button>
      <div class="lightbox__stage"><img class="lightbox__img" alt=""></div>
    `
    document.body.appendChild(dialog)

    dialog.querySelector(".lightbox__close").addEventListener("click", () => dialog.close())
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog || event.target.classList.contains("lightbox__stage")) dialog.close()
    })
    dialog.querySelector(".lightbox__img").addEventListener("click", (event) => {
      event.stopPropagation()
      dialog.classList.toggle("lightbox--zoomed")
    })

    this.dialog = dialog
    return dialog
  }
}
