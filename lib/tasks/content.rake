# Content-factory tasks: loading seeds and the MECHANICAL half of QA.
#
#   bin/rails content:import[slug] — import ONE profession seed (db/seeds/curriculum/
#                                    <slug>) into the DB; omit the slug to import the
#                                    whole tree (same as db:seed). New content lands
#                                    as draft (status from the yml is honored); a
#                                    re-import never overwrites human-edited rows.
#   bin/rails content:audit        — theory lessons WRITTEN but lacking the self-check
#                                    questions a theory lesson should end on
#   bin/rails content:links        — resource links that no longer resolve (they rot
#                                    silently on their own)
#   bin/rails content:check        — the whole mechanical QA pass: audit + links
#
# audit/links are deliberately NARROW — they do NOT enforce completeness (not every
# lesson needs practice or a diagram; usefulness over box-ticking). The JUDGMENT
# half of QA — clarity, technical correctness, depth, whether a diagram/practice
# helps — is a Claude Code console review. See tools/QA_REVIEW.md.
namespace :content do
  desc "Import one profession seed into the DB (omit slug for all): bin/rails content:import[svarshchik]"
  task :import, [ :slug ] => :environment do |_task, args|
    CurriculumImporter.run(only: args[:slug])
  end

  desc "Flag written theory lessons missing self-check questions"
  task audit: :environment do
    missing = Lesson.where(kind: "lesson").select(&:missing_self_check?)

    if missing.empty?
      puts "✓ Все написанные теоретические уроки содержат блок самопроверки."
    else
      puts "Теория без вопросов для самопроверки (#{missing.size}) — стоит добавить:"
      missing.each { |lesson| puts "  · #{lesson.slug}  «#{lesson.title}»" }
    end
  end

  desc "Check that every resource link still resolves (hits the network — slow)"
  task links: :environment do
    require "net/http"

    check = lambda do |url|
      uri = URI.parse(url)
      return :skip unless uri.is_a?(URI::HTTP)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                 open_timeout: 8, read_timeout: 8) do |http|
        http.get(uri.request_uri, "User-Agent" => "Mozilla/5.0 (IndustrialProfi link check)")
      end
      Integer(response.code).between?(200, 399) ? :ok : "HTTP #{response.code}"
    rescue StandardError => e
      e.class.name
    end

    dead = []
    Resource.where.not(url: [ nil, "" ]).find_each do |resource|
      result = check.call(resource.url)
      dead << [ resource, result ] unless result == :ok || result == :skip
    end

    if dead.empty?
      puts "✓ Битых ссылок не найдено."
    else
      puts "Недоступные ссылки (#{dead.size}) — проверь вручную (403/таймаут часто = защита от ботов, ложная тревога):"
      dead.each { |resource, why| puts "  · [#{resource.lesson&.slug}] #{why} — #{resource.url}  «#{resource.title}»" }
    end
  end

  desc "Run the whole mechanical QA pass (audit + links)"
  task check: %i[audit links]
end
