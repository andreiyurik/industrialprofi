// Minimal service worker: it exists so the app is installable (home-screen
// icon, standalone window) and so a dropped connection shows a branded page
// instead of the browser's error.
//
// It deliberately does NOT cache pages or assets. Caching personalised HTML
// (the header carries the signed-in name and progress) risks leaking it on a
// shared device and serving stale content after a deploy — real cost for a
// benefit nobody needs before launch. When offline reading is actually wanted,
// the right shape is a per-lesson "Save offline" button (intentional, public
// content only), not a blanket cache. See the decision notes in the PR.
const CACHE = "industrialprofi-offline-v1"
const OFFLINE_URL = "/offline.html"

self.addEventListener("install", (event) => {
  // Precache only the offline page, so it's available when the network is down.
  event.waitUntil(caches.open(CACHE).then((cache) => cache.add(OFFLINE_URL)))
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  // Only catch full-page navigations; on network failure, show the offline page.
  // Everything else (assets, XHR) is left to the browser and its HTTP cache.
  if (event.request.mode !== "navigate") return

  event.respondWith(fetch(event.request).catch(() => caches.match(OFFLINE_URL)))
})
