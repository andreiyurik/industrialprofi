// Load a controller the first time an element asks for it by data-controller —
// including elements Turbo inserts later, which the loader watches for. Eager
// loading fetched all 30-odd on every page, so a reader paid 77 KB of chart.js
// for the two admin pages that draw a graph.
import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("controllers", application)
