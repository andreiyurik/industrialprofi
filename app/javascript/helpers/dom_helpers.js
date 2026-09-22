// Fizzy pattern: one helpers module instead of re-authoring drag-and-drop plumbing.

// The standard "what am I dropping before" test; candidates should already
// exclude the dragged node(s).
export function elementAfter(candidates, y) {
  return candidates.find((el) => {
    const box = el.getBoundingClientRect()
    return y < box.top + box.height / 2
  })
}
