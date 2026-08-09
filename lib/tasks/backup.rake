namespace :backup do
  desc "Consistent SQLite snapshot into storage/backups/pull.sqlite3 (safe under live writes)"
  task snapshot: :environment do
    target = Rails.root.join("storage/backups/pull.sqlite3")
    FileUtils.mkdir_p(target.dirname)
    FileUtils.rm_f(target)
    # VACUUM INTO writes a compact, transactionally-consistent copy — SQLite's
    # own answer to "back up a live database" (same guarantee as .backup).
    ActiveRecord::Base.connection.execute("VACUUM INTO #{ActiveRecord::Base.connection.quote(target.to_s)}")
    puts "Snapshot: #{target} (#{(File.size(target) / 1024.0 / 1024).round(1)} MB)"
  end
end
