namespace :search do
  desc "Rebuild the lesson search index (FTS5) from scratch"
  task rebuild: :environment do
    puts "Search index rebuilt: #{LessonSearch.rebuild} lessons."
  end
end
