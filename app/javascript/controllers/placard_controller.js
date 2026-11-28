import { Controller } from "@hotwired/stimulus"

const GRAVITY = 42
const DAMPING = 1.2
const LIMIT = 1.25
const REST = 0.003
const DROP = 0.55

// A sign on a nail: a damped pendulum that can be pushed, dragged and let go.
export default class extends Controller {
  static targets = [ "plate" ]

  connect() {
    this.angle = 0
    this.speed = 0
    this.still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (this.still) return

    this.onScroll = () => this.#sway()
    this.lastScroll = window.scrollY
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.observer = new IntersectionObserver(([ entry ]) => this.#seen(entry.isIntersecting))
    this.observer.observe(this.element)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    this.running = false
    this.held = null
    window.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  grab(event) {
    if (this.still || event.button > 0) return
    this.plateTarget.setPointerCapture(event.pointerId)
    this.held = { offset: this.#pointerAngle(event) - this.angle, start: this.angle, moved: false, time: event.timeStamp }
    this.dragged = false
    this.speed = 0
  }

  drag(event) {
    if (!this.held) return this.#brush(event)
    if (event.buttons === 0) return this.release(event)
    const angle = this.#clamp(this.#pointerAngle(event) - this.held.offset, LIMIT)
    const elapsed = Math.max(event.timeStamp - this.held.time, 1) / 1000
    this.speed = this.#clamp((angle - this.angle) / elapsed, 12)
    if (Math.abs(angle - this.held.start) > 0.04) this.held.moved = true
    this.held.time = event.timeStamp
    this.angle = angle
    this.#draw()
  }

  release(event) {
    if (!this.held) return
    this.dragged = this.held.moved && event.type === "pointerup"
    if (event.timeStamp - this.held.time > 100) this.speed = 0
    this.held = null
    this.#run()
  }

  nudge(event) {
    this.entering = !this.still && event.pointerType === "mouse"
  }

  // A drag that ends over the plate must not follow the link; a keyboard click has no detail.
  go(event) {
    if (this.dragged && event.detail > 0) event.preventDefault()
    this.dragged = false
  }

  // Private

  #seen(visible) {
    if (visible && !this.visible && !this.held) {
      this.angle = DROP
      this.speed = 0
      this.#run()
    }
    this.visible = visible
  }

  // pointerenter carries no movement, so the push comes from the first move after it.
  #brush(event) {
    if (!this.entering) return
    this.entering = false
    this.speed -= this.#clamp(event.movementX || 0, 40) * 0.07
    this.#run()
  }

  #sway() {
    const delta = window.scrollY - this.lastScroll
    this.lastScroll = window.scrollY
    if (this.held || !this.element.offsetParent) return
    this.speed += this.#clamp(delta, 80) * 0.004
    this.#run()
  }

  #run() {
    if (this.running) return
    this.running = true
    let last = performance.now()
    const step = now => {
      const dt = Math.min(Math.max(now - last, 0) / 1000, 0.032)
      last = now
      if (!this.held) {
        this.speed += (-GRAVITY * Math.sin(this.angle) - DAMPING * this.speed) * dt
        this.angle = this.#clamp(this.angle + this.speed * dt, LIMIT)
      }
      const resting = !this.held && Math.abs(this.angle) < REST && Math.abs(this.speed) < REST * 10
      if (resting) this.angle = this.speed = 0
      this.#draw()
      this.running = !resting && this.element.isConnected
      if (this.running) this.frame = requestAnimationFrame(step)
    }
    this.frame = requestAnimationFrame(step)
  }

  #draw() {
    this.plateTarget.style.rotate = `${this.angle.toFixed(4)}rad`
  }

  // The plate's angle that would put its axis under the pointer; the nail is the hanger's top centre.
  #pointerAngle(event) {
    const box = this.element.getBoundingClientRect()
    return -Math.atan2(event.clientX - (box.left + box.width / 2), Math.max(event.clientY - box.top, 1))
  }

  #clamp(value, limit) {
    return Math.max(-limit, Math.min(limit, value))
  }
}
