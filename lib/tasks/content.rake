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
  # DEBT prints as a count + the three worst — a wall of lines trains you to stop reading.
  desc "Errors first, then debt as counts: bin/rails content:audit — add [full] for every line"
  task :audit, [ :mode ] => :environment do |_task, args|
    full = args[:mode].to_s == "full"
    errors, debt = [], []

    error = ->(title, items) { errors << [ title, items ] if items.any? }
    owe   = ->(title, items) { debt << [ title, items ] if items.any? }

    error.call "Неизвестные эмблемы — имени нет в наборе, см. content:icons",
      (Path.all.to_a + Course.all.to_a)
        .reject { |record| record.icon.blank? || Icon.emblem?(record.icon) }
        .map { |record| "#{record.slug}  →  #{record.icon}" }

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

    # Calculator::ALL hardcodes lesson slugs — a rename stops the link silently.
    error.call "Калькуляторы с битой привязкой — ссылка тихо исчезла со страницы",
      Calculator.all
        .select { |calculator| calculator.lesson_slug.present? && !Lesson.exists?(slug: calculator.lesson_slug) }
        .map { |calculator| "#{calculator.slug} → /lessons/#{calculator.lesson_slug}" }

    error.call "Заглушечные ссылки — замени на реальный источник или сними ресурс",
      Resource.where("url LIKE '%example.com%' OR url LIKE '%example.org%' OR url LIKE '%example.net%' OR url LIKE '%watch?v=example%'")
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] #{r.url}" }
    error.call "consultant.ru/garant.ru — читатель не откроет без регистрации",
      Resource.where("url LIKE '%consultant.ru%' OR url LIKE '%garant.ru%'")
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] #{r.url}" }

    # The description is also <meta name="description">, cut at 160 chars in the snippet.
    owe.call "Описания длиннее 160 — в сниппете обрежется на полуслове",
      (Path.all.to_a + Course.all.to_a + Lesson.all.to_a)
        .select { |record| record.description.to_s.length > 160 }
        .sort_by { |record| -record.description.to_s.length }
        .map { |record| "#{record.description.to_s.length}  #{record.slug}" }

    owe.call "Статьи без единой внутренней ссылки — норма 3–7 на статью", unlinked

    owe.call "Обязательные документы без заметки «что именно смотреть»",
      Resource.where(required: true, note: [ nil, "" ], kind: %w[norm document doc book])
              .includes(:lesson).map { |r| "[#{r.lesson&.slug}] «#{r.title.to_s.truncate(70)}»" }

    # Narrow on purpose so legitimately long ГОСТ/приказ names are never flagged.
    commentary = /\([^)]*(провер|актуальн|утратил|предыдущ|см\.)[^)]*\)/i
    owe.call "Пояснения приклеены к названию — перенеси в note",
      Resource.includes(:lesson)
              .select { |r| r.title.to_s.match?(commentary) || (%w[software tool].include?(r.kind) && r.title.to_s.match?(/\s—\s/)) }
              .map { |r| "[#{r.lesson&.slug}] #{r.kind}  «#{r.title.to_s.truncate(90)}»" }

    owe.call "Теория без блока самопроверки",
      Lesson.where(kind: "lesson").select(&:missing_self_check?).map { |l| "#{l.slug}  «#{l.title}»" }

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

  # Deliberate: authoring never invents a link (name-only entry beats a guessed URL).
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
