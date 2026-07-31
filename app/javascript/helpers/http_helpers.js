// Small shared HTTP plumbing — the Fizzy pattern of one helpers module instead
// of re-authoring fetch/token boilerplate inside every controller.

// The CSRF token Rails stamps into <head>, needed on any fetch()-based write.
export function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}
