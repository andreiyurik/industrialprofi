# Content-factory tasks: loading seeds and the MECHANICAL half of QA.
#
#   bin/rails content:import[slug] — import ONE profession seed (db/seeds/curriculum/
#                                    <slug>) into the DB; omit the slug to import the
#                                    whole tree (same as db:seed). New content lands
#                                    as draft (status from the yml is honored); a
#                                    re-import never overwrites human-edited rows.
#   bin/rails content:export[slug] — write ONE profession from the DB back into the
#                                    importer's YAML/Markdown tree (tmp/export/<slug>)
#                                    — a portable content pack; see CurriculumExporter
#   bin/rails content:audit        — ERRORS in full, then DEBT as counts. An error
#                                    means a reader sees something broken: a dead
#                                    internal slug, a link missing the /ru prefix
#                                    (it 301s, so nobody notices), an unknown emblem
#                                    or callout marker (both render as something
#                                    else, silently), a calculator bound to a lesson
#                                    that no longer exists, a placeholder or
#                                    paywalled URL. Errors are rare — their silence
#                                    is the product. Debt is unfinished authoring
#                                    (long descriptions, missing reader notes,
#                                    lessons not yet woven into the map): a count
#                                    and the three worst, `content:audit[full]`
#                                    for every line.
#   bin/rails content:queue        — the curation queue: resources whose name is
#                                    written but the link isn't found yet. Not an
#                                    error — authoring never invents a URL.
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

  desc "Export one profession to the importer's YAML tree: bin/rails content:export[svarshchik]"
  task :export, [ :slug ] => :environment do |_task, args|
    path = Path.find_by(slug: args[:slug])
    abort "Профессия «#{args[:slug]}» не найдена. Использование: content:export[slug]" unless path

    CurriculumExporter.run(path)
  end

  desc "List the emblem names an author may put in path.yml / course.yml"
  task icons: :environment do
    puts "Эмблемы, доступные для `icon:` (#{Icon.emblems.size}). Другие имена импорт отклонит."
    puts "Пусто = глава наследует эмблему профессии — это нормальный ответ."
    Icon.emblems.each_slice(4) { |row| puts "  #{row.map { it.ljust(26) }.join.rstrip}" }
  end
  # Two levels, deliberately. An ERROR means something is broken and a reader
  # sees it — these are rare, so they print in full and their silence is the
  # product. DEBT means unfinished authoring: real, but a campaign, not a
  # regression, so it prints as a count and the three worst. A report that
  # always prints hundreds of lines teaches you to stop reading it.
  desc "Errors first, then debt as counts: bin/rails content:audit — add [full] for every line"
  task :audit, [ :mode ] => :environment do |_task, args|
    full = args[:mode].to_s == "full"
    errors, debt = [], []

    # `items` are already formatted lines; `error` prints all of them, `owe`
    # prints three unless asked for everything.
    error = ->(title, items) { errors << [ title, items ] if items.any? }
    owe   = ->(title, items) { debt << [ title, items ] if items.any? }

    # Emblems: an AI draft can invent a plausible name that has no file.
    error.call "Неизвестные эмблемы — имени нет в наборе, см. content:icons",
      (Path.all.to_a + Course.all.to_a)
        .reject { |record| record.icon.blank? || Icon.emblem?(record.icon) }
        .map { |record| "#{record.slug}  →  #{record.icon}" }

    # Internal links: a slug that doesn't exist is a 404 for the reader; a link
    # without the /ru prefix still WORKS (the app 301s it), which is exactly why
    # nobody notices it costing a redirect. Both are errors, one is just quieter.
    known_slugs = Lesson.pluck(:slug).to_set
    broken, unprefixed, unlinked = [], [], []
    Lesson.includes(:path).find_each do |lesson|
      next unless lesson.has_body?

      links = lesson.linked_lesson_slugs
      unlinked << "#{lesson.path.slug} · #{lesson.slug}" if links.empty?
      (links - known_slugs.to_a).each { |slug| broken << "#{lesson.slug} → /lessons/#{slug}" }
      bare = [ lesson.body.to_s, lesson.task.to_s, lesson.description.to_s, lesson.rich_body&.body.to_s ]
             .join(" ").scan(%r{(?<!/ru)/lessons/[a-z0-9\-]+}).size
      unprefixed << "#{lesson.slug} (#{bare})" if bare.positive?
    end

    error.call "Внутренние ссылки в никуда — битый slug", broken
    error.call "Ссылки без префикса /ru — лишний 301, чинит content:localize_links", unprefixed

    # A callout is a blockquote whose first line is a marker from a small fixed
    # set. An unknown or Latin one renders as an ordinary grey quote instead.
    known_markers = ApplicationHelper::CALLOUTS.keys
    stray = Hash.new { |hash, key| hash[key] = [] }
    Lesson.find_each do |lesson|
      [ lesson.body.to_s, lesson.task.to_s, lesson.rich_body&.body.to_s ].join(" ")
        .scan(/\[!([^\]\n]{1,30})\]/).flatten.uniq
        .reject { |marker| known_markers.include?(marker) }
        .each { |marker| stray[marker] << lesson.slug }
    end
    error.call "Неизвестные маркеры выносок — отрисуются серой цитатой (можно: #{known_markers.join(", ")})",
      stray.sort.map { |marker, slugs| "[!#{marker}] — #{slugs.first(5).join(", ")}#{" …" if slugs.size > 5}" }

    # Calculator::ALL points at lessons by slug — the one place where code
    # hardcodes content. Rename the lesson and the link stops rendering, silently.
    error.call "Калькуляторы с битой привязкой — ссылка тихо исчезла со страницы",
      Calculator.all
        .select { |calculator| calculator.lesson_slug.present? && !Lesson.exists?(slug: calculator.lesson_slug) }
        .map { |calculator| "#{calculator.slug} → /lessons/#{calculator.lesson_slug}" }

    # Placeholder URLs left from authoring, and domains that answer 200 but
    # gate the document behind registration — content:links can't see either.
    error.call "Заглушечные ссылки — замени на реальный источник или сними ресурс",
      Resource.where("url LIKE '%example.com%' OR url LIKE '%example.org%' OR url LIKE '%example.net%' OR url LIKE '%watch?v=example%'")
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] #{r.url}" }
    error.call "consultant.ru/garant.ru — читатель не откроет без регистрации",
      Resource.where("url LIKE '%consultant.ru%' OR url LIKE '%garant.ru%'")
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] #{r.url}" }

    # ── Debt: unfinished authoring, not breakage ──────────────────────────────

    # The description is also <meta name="description">, which the view cuts at
    # 160 characters — invisible on the site, mangled in search results.
    owe.call "Описания длиннее 160 — в сниппете обрежется на полуслове",
      (Path.all.to_a + Course.all.to_a + Lesson.all.to_a)
        .select { |record| record.description.to_s.length > 160 }
        .sort_by { |record| -record.description.to_s.length }
        .map { |record| "#{record.description.to_s.length}  #{record.slug}" }

    owe.call "Статьи без единой внутренней ссылки — норма 3–7 на статью", unlinked

    owe.call "Обязательные документы без заметки «что именно смотреть»",
      Resource.where(required: true, note: [ nil, "" ], kind: %w[norm document doc book])
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] «#{r.title.to_s.truncate(70)}»" }

    # title = the citable NAME; explanations belong in `note`. Two narrow smells
    # so legitimately long ГОСТ/приказ names are never flagged.
    commentary = /\([^)]*(провер|актуальн|утратил|предыдущ|см\.)[^)]*\)/i
    owe.call "Пояснения приклеены к названию — перенеси в note",
      Resource.includes(:lesson)
              .select { |r| r.title.to_s.match?(commentary) || (%w[software tool].include?(r.kind) && r.title.to_s.match?(/\s—\s/)) }
              .map { |r| "[#{r.lesson&.slug}] #{r.kind}  «#{r.title.to_s.truncate(90)}»" }

    owe.call "Теория без блока самопроверки",
      Lesson.where(kind: "lesson").select(&:missing_self_check?).map { |l| "#{l.slug}  «#{l.title}»" }

    # ── Report ───────────────────────────────────────────────────────────────

    if errors.empty?
      puts "✓ Ошибок нет."
    else
      puts "ОШИБКИ (#{errors.sum { |_, items| items.size }}) — чинить:"
      errors.each do |title, items|
        puts "  #{title} (#{items.size}):"
        items.each { |item| puts "    · #{item}" }
      end
    end

    unless debt.empty?
      puts "", "ДОЛГ — работа, а не поломка#{" (bin/rails 'content:audit[full]' — весь список)" unless full}:"
      debt.each do |title, items|
        puts "  #{items.size.to_s.rjust(4)}  #{title}"
        (full ? items : items.first(3)).each { |item| puts "        · #{item}" }
        puts "        … и ещё #{items.size - 3}" if !full && items.size > 3
      end
    end
  end

  # Not an audit finding: authoring deliberately leaves a norm/book/doc as a
  # name-only entry rather than inventing a link («качественная ссылка или
  # никакой»). This is the curation queue — the documents still waiting for one.
  desc "The curation queue: resources whose name is written but the link isn't found yet"
  task queue: :environment do
    urlless = Resource.where(url: [ nil, "" ]).includes(:lesson).order(:lesson_id)

    if urlless.none?
      puts "✓ У каждого ресурса есть ссылка."
    else
      puts "Ждут реальной ссылки (#{urlless.size}):"
      urlless.each { |r| puts "  · [#{r.lesson&.slug}] #{r.kind}  «#{r.title.to_s.truncate(70)}»" }
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

  desc "One-time after the URL locale prefix: point internal lesson links at /ru (idempotent)"
  task localize_links: :environment do
    lessons = 0
    Lesson.find_each do |lesson|
      changes = %i[body task description].filter_map { |column|
        text = lesson[column]
        [ column, text.gsub("](/lessons/", "](/ru/lessons/") ] if text&.include?("](/lessons/")
      }.to_h
      next if changes.empty?

      lesson.update!(changes)
      lessons += 1
    end

    rich_texts = 0
    ActionText::RichText.where("body LIKE ?", '%href="/lessons/%').find_each do |rich_text|
      rich_text.update!(body: rich_text.body.to_s.gsub('href="/lessons/', 'href="/ru/lessons/'))
      rich_texts += 1
    end

    puts "Rewrote internal links: #{lessons} lessons, #{rich_texts} rich texts."
  end
end
