import "@hotwired/turbo-rails"
import "controllers"

// Lexxy is 200 KB over the wire, loaded lazily only for an editor or for
// already-highlighted rich text (pre[data-language], set once an edit freezes it).
const LEXXY_NEEDED = "lexxy-editor, pre[data-language]"

let lexxy = null

function loadLexxy() {
  if (lexxy) return lexxy

  // Started in parallel, awaited only after configure() — see below.
  const prism = import("helpers/prism_st")

  lexxy = import("lexxy").then(async (module) => {
    // Image-only, h2/h3 only (h1 clashes with the page title), no colour highlight.
    // Lexxy registers its elements from setTimeout(0); this microtask still lands first.
    module.configure({
      default: {
        toolbar: { upload: "image" },
        headings: [ "h2", "h3" ],
        highlight: { buttons: { color: [], "background-color": [] } }
      }
    })

    // Importing lexxy populates window.Prism; this lights up the `st` (IEC
    // 61131-3 Structured Text) grammar for both the editor and rendered code.
    const { registerStructuredText } = await prism
    registerStructuredText()

    return module
  })

  return lexxy
}

// Saved rich text renders as bare <pre data-language>; Lexxy ships highlightCode()
// for display but leaves calling it to the app.
document.addEventListener("turbo:load", () => {
  if (!document.querySelector(LEXXY_NEEDED)) return
  loadLexxy().then(({ highlightCode }) => highlightCode())
})

// HTTPS only: localhost also counts as a secure origin, so without this check the
// worker installs in development too, and a restarted dev server reads as "no
// connection" instead of "the server is down".
if ("serviceWorker" in navigator && location.protocol === "https:") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").catch(() => {})
  })
}
