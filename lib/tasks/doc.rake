# A browsable map of the app, generated on demand — not documentation we maintain.
#
# RDoc ships with Ruby, so this needs no gem. What it's actually good for is the
# view from above on a fat class: ancestors, included concerns, the full method
# list — plus every Markdown doc rendered as a page beside the code.
#
# What it CANNOT show, and why we don't chase it: RDoc attaches a comment to the
# next *definition* (class / module / def / constant). `has_many`, `validates` and
# `scope` are plain method calls, so the comments above them — which is where this
# codebase keeps its reasoning — are dropped. The reasoning lives in
# docs/ARCHITECTURE.md and CLAUDE.md on purpose; read those, not this.
namespace :doc do
  desc "Generate a browsable HTML map of the app into doc/ (RDoc, no gem needed)"
  task :map do
    sh "rdoc --quiet --output doc --title IndustrialProfi --main README.md " \
       "app/models app/controllers app/helpers lib README.md docs"
    puts "→ doc/index.html"
  end
end
