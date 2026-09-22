# Generated on demand — RDoc only sees class/module/def, so reasoning stays in docs/.
namespace :doc do
  desc "Generate a browsable HTML map of the app into doc/ (RDoc, no gem needed)"
  task :map do
    sh "rdoc --quiet --output doc --title IndustrialProfi --main README.md " \
       "app/models app/controllers app/helpers lib README.md docs"
    puts "→ doc/index.html"
  end
end
