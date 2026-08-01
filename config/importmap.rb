# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/helpers", under: "helpers"
# Locale-agnostic calculator maths + number formatting, shared by the shared
# controller and the per-calculator ones.
pin_all_from "app/javascript/calculators", under: "calculators"
pin "lexxy", to: "lexxy.min.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "rough-notation", to: "rough-notation.js" # vendored, self-hosted (vendor/javascript)
# Vendored, self-hosted (vendor/javascript) — the plain jspm dist/chart.js build
# imports from jspm-internal shared chunks (relative "../_/<hash>.js" paths) that
# don't exist once vendored standalone, so this is esm.sh's self-contained
# ?bundle build instead: zero external imports, single file.
pin "chart.js", to: "chart.js.js" # @4.5.1
