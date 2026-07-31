// Shared DOM geometry helpers — the Fizzy pattern of one helpers module
// instead of re-authoring drag-and-drop plumbing per controller.

// Find the first element in `candidates` whose vertical midpoint sits below
// `y` — the standard "what am I dropping before" test for a y-ordered
// drag-and-drop list. `candidates` should already exclude the dragged node(s).
export function elementAfter(candidates, y) {
  return candidates.find((el) => {
    const box = el.getBoundingClientRect()
    return y < box.top + box.height / 2
  })
}
