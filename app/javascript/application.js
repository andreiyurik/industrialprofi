// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import { highlightCode } from "lexxy"

// The editor highlights code live, but SAVED rich text renders as bare
// <pre data-language> — Lexxy ships highlightCode() for display and leaves
// calling it to the app. Without this, a lesson loses its code colors the
// moment an editor's first edit freezes it into rich text.
document.addEventListener("turbo:load", () => highlightCode())

// Register the service worker so visited lessons stay readable offline.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").catch(() => {})
  })
}
