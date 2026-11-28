import { Controller } from "@hotwired/stimulus"

const GRAVITY = 42
const DAMPING = 0.9
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
    this.observer = new IntersectionObserver(([ entry ]) => entry.isIntersecting && this.#drop())
    this.observer.observe(this.element)
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    window.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  grab(event) {
    if (this.still || event.button > 0) return
    this.plateTarget.setPointerCapture(event.pointerId)
    this.held = { offset: this.#pointerAngle(event) - this.angle, moved: false, time: event.timeStamp }
    this.speed = 0
  }

  drag(event) {
    if (!this.held) return
    const angle = this.#clamp(this.#pointerAngle(event) - this.held.offset, LIMIT)
    const elapsed = Math.max(event.timeStamp - this.held.time, 1) / 1000
    this.speed = this.#clamp((angle - this.angle) / elapsed, 12)
    if (Math.abs(angle - this.angle) > 0.02) this.held.moved = true
    this.held.time = event.timeStamp
    this.angle = angle
    this.#draw()
  }

  release() {
    if (!this.held) return
    this.dragged = this.held.moved
    this.held = null
    this.#run()
  }

  nudge(event) {
    if (this.still || this.held || event.pointerType !== "mouse") return
    this.speed -= this.#clamp(event.movementX, 40) * 0.07
    this.#run()
  }

  // A drag that ends over the plate must not follow the link.
  go(event) {
    if (this.dragged) event.preventDefault()
    this.dragged = false
  }

  // Private

  #drop() {
    if (this.held || this.running) return
    this.angle = DROP
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
      const dt = Math.min((now - last) / 1000, 0.032)
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
