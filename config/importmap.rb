# Only these four load on every page — `preload: true` here put all 53 modules on the wire once.
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers", preload: false
pin_all_from "app/javascript/helpers", under: "helpers", preload: false
pin_all_from "app/javascript/calculators", under: "calculators", preload: false
pin "lexxy", to: "lexxy.min.js", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js", preload: false
pin "rough-notation", to: "rough-notation.js", preload: false
# esm.sh's self-contained ?bundle build — the plain jspm one breaks standalone.
pin "chart.js", to: "chart.js.js", preload: false # @4.5.1
