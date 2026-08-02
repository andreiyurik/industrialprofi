// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Lexxy is 200 KB over the wire — by far the heaviest thing we could ship, and
// a reader needs none of it. Two things want it, both narrow: the editor on the
// handful of pages that write rich text, and colouring code inside SAVED rich
// text. Markdown lessons are highlighted server-side by rouge and never carry
// data-language, so this matches nothing until an editor's first edit freezes a
// lesson into rich text — which is exactly when we want it to start matching.
const LEXXY_NEEDED = "lexxy-editor, pre[data-language]"

let lexxy = null

function loadLexxy() {
  if (lexxy) return lexxy

  // Started in parallel, awaited only after configure() — see below.
  const prism = import("helpers/prism_st")

  lexxy = import("lexxy").then(async (module) => {
    // App-wide editor defaults (merged into Lexxy's `default` preset, so every
    // rich_text_area inherits them — one place, per the maintenance goal):
    //   • upload button = image only (we never allow arbitrary file attachments);
    //   • headings limited to h2/h3, matching our lesson format (## sections, on
    //     which enrich_prose builds anchors) — h1 clashes with the page title;
    //   • no text-colour highlight buttons — content is monochrome-first, colour
    //     carries meaning only in badges, never as decorative coloured prose.
    // Lexxy defines its custom elements from a setTimeout(0) so that global
    // configuration can land first; this call runs synchronously off the import,
    // i.e. in a microtask, so it still beats that timer.
    module.configure({
      default: {
        toolbar: { upload: "image" },
        headings: [ "h2", "h3" ],
        highlight: { buttons: { color: [], "background-color": [] } }
      }
    })

    // Teach Lexxy's bundled Prism our industrial language: IEC 61131-3
    // Structured Text (PLC). Importing lexxy populated window.Prism, so this
    // lights up the `st` grammar for both the editor and rendered code.
    const { registerStructuredText } = await prism
    registerStructuredText()

    return module
  })

  return lexxy
}

// The editor highlights code live, but SAVED rich text renders as bare
// <pre data-language> — Lexxy ships highlightCode() for display and leaves
// calling it to the app. Without this, a lesson loses its code colors the
// moment an editor's first edit freezes it into rich text.
document.addEventListener("turbo:load", () => {
  if (!document.querySelector(LEXXY_NEEDED)) return
  loadLexxy().then(({ highlightCode }) => highlightCode())
})

// Register the service worker so visited lessons stay readable offline. HTTPS only,
// which in practice means production (kamal-proxy terminates SSL): a browser treats
// http://localhost as a secure origin too, so without this the worker installs in
// development — where offline reading is pointless and its one behaviour is to answer
// every failed navigation with offline.html. A restarted dev server then reads as
// "нет подключения к интернету" instead of "the server is down".
if ("serviceWorker" in navigator && location.protocol === "https:") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker").catch(() => {})
  })
}
