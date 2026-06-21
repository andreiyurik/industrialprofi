import { Controller } from "@hotwired/stimulus"

// The lesson TOC ("В этом уроке"). Two jobs:
//  - mark the entry for the section under the reading line (30% down the
//    viewport), tracked with a passive scroll listener;
//  - on click, glide to the section smoothly, mark the clicked entry at once
//    (no flicker through the sections passed on the way), and update the URL
//    hash with replaceState so Back still leaves the page in one step.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.anchored = new Map() // anchor element -> its TOC link, document order

    this.linkTargets.forEach((link) => {
      const anchor = this.anchorFor(link)
      if (anchor) this.anchored.set(anchor, link)
    })

    this.onScroll = () => {
      if (this.scheduled) return
      this.scheduled = true
      requestAnimationFrame(() => {
        this.scheduled = false
        this.update()
      })
    }
    window.addEventListener("scroll", this.onScroll, { passive: true })

    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    clearTimeout(this.settleTimer)
  }

  // data-action="lesson-toc#jump" on every TOC link.
  jump(event) {
    const link = event.currentTarget
    const anchor = this.anchorFor(link)
    if (!anchor) return // let the browser handle a dead link

    event.preventDefault()
    this.mark(link)

    // Hold the highlight on the chosen entry while the page glides past the
    // sections in between, then hand tracking back to the scroll listener.
    this.settling = true
    clearTimeout(this.settleTimer)
    this.settleTimer = setTimeout(() => {
      this.settling = false
      this.update()
    }, 700)

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    anchor.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth" })
    history.replaceState(history.state, "", link.getAttribute("href"))
  }

  update() {
    if (this.settling) return

    const entries = [...this.anchored.entries()]
    if (entries.length === 0) return

    // At the very bottom the last sections can never reach the reading line —
    // there the deepest entry wins.
    const atBottom =
      window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
    if (atBottom) {
      this.mark(entries.at(-1)[1])
      return
    }

    const line = window.innerHeight * 0.3
    let current = entries[0][1]
    for (const [anchor, link] of entries) {
      if (anchor.getBoundingClientRect().top <= line) current = link
    }
    this.mark(current)
  }

  mark(current) {
    this.linkTargets.forEach((link) => {
      if (link === current) {
        link.setAttribute("aria-current", "true")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }

  anchorFor(link) {
    return document.getElementById(decodeURIComponent(link.getAttribute("href")).slice(1))
  }
}
