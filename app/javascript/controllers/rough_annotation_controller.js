import { Controller } from "@hotwired/stimulus"
import { annotate } from "rough-notation"

// Honors prefers-reduced-motion by drawing instantly, and plays its entrance
// animation once per session.
const PLAYED_KEY = "rough-annotation-played"

export default class extends Controller {
  static values = {
    type: { type: String, default: "underline" },
    color: { type: String, default: "" },
    strokeWidth: { type: Number, default: 2 },
    padding: { type: Number, default: 4 },
    duration: { type: Number, default: 900 },
    iterations: { type: Number, default: 2 },
    delay: { type: Number, default: 250 },
  }

  connect() {
    // Turbo snapshots the page BEFORE disconnect(), so the annotation SVG would
    // be cached and duplicated on restore — remove it ahead of the snapshot.
    this.beforeCache = () => this.annotation?.remove()
    document.addEventListener("turbo:before-cache", this.beforeCache)

    const instant = window.matchMedia("(prefers-reduced-motion: reduce)").matches || this.#playedThisSession
    this.annotation = annotate(this.element, {
      type: this.typeValue,
      color: this.#resolveColor(this.colorValue),
      strokeWidth: this.strokeWidthValue,
      padding: this.paddingValue,
      iterations: this.iterationsValue,
      animationDuration: this.durationValue,
      animate: !instant,
      multiline: true,
    })
    this.#whenVisible(() => this.#draw(instant))
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
    clearTimeout(this.timer)
    this.observer?.disconnect()
    this.annotation?.remove()
  }

  // Private

  // Draw only after web fonts are ready: the async font (Inter Tight) reflows the
  // box, so drawing earlier mislays the stroke against fallback metrics.
  #draw(instant) {
    const show = () => {
      this.timer = setTimeout(() => {
        this.annotation.show()
        this.#markPlayed()
      }, instant ? 0 : this.delayValue)
    }
    if (document.fonts && document.fonts.status !== "loaded") {
      document.fonts.ready.then(show)
    } else {
      show()
    }
  }

  // Draws only once the element scrolls into view; above-the-fold elements draw immediately.
  #whenVisible(callback) {
    if (!("IntersectionObserver" in window)) return callback()
    this.observer = new IntersectionObserver((entries, observer) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        observer.disconnect()
        callback()
      }
    }, { threshold: 0.5 })
    this.observer.observe(this.element)
  }

  // Guarded: sessionStorage can throw with cookies blocked; a decorative layer
  // must never take the controller down.
  get #playedThisSession() {
    try { return sessionStorage.getItem(PLAYED_KEY) === "1" } catch { return false }
  }

  #markPlayed() {
    try { sessionStorage.setItem(PLAYED_KEY, "1") } catch {}
  }

  // A CSS custom-property (e.g. "--color-link") is read back via a throwaway probe.
  #resolveColor(input) {
    const value = input || "--color-link"
    if (!value.startsWith("--")) return value
    const probe = document.createElement("span")
    probe.style.cssText = `color: var(${value}); display: none`
    document.body.appendChild(probe)
    const color = getComputedStyle(probe).color
    probe.remove()
    return color
  }
}
