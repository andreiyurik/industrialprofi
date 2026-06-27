// Shared timing utilities — the Fizzy pattern of one helpers module instead of
// re-authoring rAF/setTimeout plumbing inside every controller. Only what the
// controllers actually use lives here; add an export when a real caller needs it.

// Coalesce rapid calls into one trailing call after `delay` ms of quiet.
export function debounce(fn, delay = 300) {
  let timer = null
  return (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }
}

// Run `fn` at most once per animation frame — the right throttle for scroll
// handlers, since it paces work to paint rather than an arbitrary interval. The
// returned handler carries cancel() to drop a frame still pending on disconnect.
export function rafThrottle(fn) {
  let frame = null
  const handler = (...args) => {
    if (frame) return
    frame = requestAnimationFrame(() => {
      frame = null
      fn(...args)
    })
  }
  handler.cancel = () => {
    if (frame) cancelAnimationFrame(frame)
    frame = null
  }
  return handler
}

// Promise that resolves on the next animation frame — `await nextFrame()`.
export function nextFrame() {
  return new Promise(requestAnimationFrame)
}

// Promise that resolves after `ms` — `await delay(120)`.
export function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}
