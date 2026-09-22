// Fizzy pattern: one helpers module instead of re-authoring rAF/setTimeout plumbing.

// Coalesce rapid calls into one trailing call after `delay` ms of quiet.
export function debounce(fn, delay = 300) {
  let timer = null
  return (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay)
  }
}

// Paces work to paint rather than an arbitrary interval; cancel() drops a pending frame.
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
