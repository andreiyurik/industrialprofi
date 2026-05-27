import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.#onIntersect(entries),
      { rootMargin: "-10% 0px -80% 0px" }
    )

    document.querySelectorAll("section[id]").forEach((section) => {
      this.observer.observe(section)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  #onIntersect(entries) {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return

      const id = entry.target.id
      this.linkTargets.forEach((link) => {
        const active = link.getAttribute("href") === `#${id}`
        link.classList.toggle("toc-link-active", active)
      })
    })
  }
}
