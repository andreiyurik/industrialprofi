import { Controller } from "@hotwired/stimulus"
import { annotate } from "rough-notation"

// Draws a hand-drawn Rough Notation annotation over the element (default: an
// underline in the app's link blue). Animates in shortly after connect; honors
// prefers-reduced-motion by drawing instantly instead. The entrance animation
// plays once per session — repeat visits get the drawn state immediately.
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

  // Draw only after web fonts are ready. rough-notation positions its stroke
  // against the element's box at show() time; the async font (Inter Tight)
  // reflows that box, so drawing earlier lays the line against fallback metrics
  // and it ends up mislaid — e.g. crossing the next title line.
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

  // Draw only once the element scrolls into view (the intended rough-notation
  // pattern) — annotations below the fold feel earned, not all fired on load.
  // Above-the-fold elements are already intersecting, so they draw immediately.
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

  // Resolve the annotation colour. A CSS custom-property name (e.g. "--color-link")
  // is read back as its used value via a throwaway probe — custom properties
  // otherwise return unresolved ("oklch(var(--lch-blue))"). Anything else passes
  // through; empty falls back to the link blue.
  // Guarded: sessionStorage can throw with cookies fully blocked, and a
  // decorative layer must never take the controller down with it.
  get #playedThisSession() {
    try { return sessionStorage.getItem(PLAYED_KEY) === "1" } catch { return false }
  }

  #markPlayed() {
    try { sessionStorage.setItem(PLAYED_KEY, "1") } catch {}
  }

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
