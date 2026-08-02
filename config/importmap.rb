# Pin npm packages by running ./bin/importmap

# Only these four are wanted on every page, so only these four are preloaded.
# `preload: true` (the default) emits a <link rel="modulepreload">, which is a
# request whether or not the page imports the module — that, not the imports,
# is what put all 53 of our modules on the wire everywhere.
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Everything below loads on demand: controllers when an element asks for one by
# data-controller (see controllers/index.js), the rest when a controller or
# application.js imports it. The Stimulus bootstrap itself is the exception —
# it IS needed on every page, so the layout preloads it by name.
pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin_all_from "app/javascript/helpers", under: "helpers", preload: false
# Locale-agnostic calculator maths + number formatting, shared by the shared
# controller and the per-calculator ones.
pin_all_from "app/javascript/calculators", under: "calculators", preload: false
pin "lexxy", to: "lexxy.min.js", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js", preload: false
pin "rough-notation", to: "rough-notation.js", preload: false # vendored, self-hosted (vendor/javascript)
# Vendored, self-hosted (vendor/javascript) — the plain jspm dist/chart.js build
# imports from jspm-internal shared chunks (relative "../_/<hash>.js" paths) that
# don't exist once vendored standalone, so this is esm.sh's self-contained
# ?bundle build instead: zero external imports, single file.
pin "chart.js", to: "chart.js.js", preload: false # @4.5.1
