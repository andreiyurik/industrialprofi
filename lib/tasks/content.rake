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
#   bin/rails content:audit        — mechanical content gaps: theory lessons missing
#                                    the self-check block, lessons with no internal
#                                    /lessons/ links (the wiki fabric), internal links
#                                    pointing at a slug that doesn't exist, internal
#                                    links missing the /ru prefix (they 301, so nobody
#                                    notices), descriptions past the 160-char cut of
#                                    the search snippet, unknown callout markers (they
#                                    render as a plain grey quote), calculators bound
#                                    to a lesson slug that no longer exists, required
#                                    long-form documents without a reader note
#                                    («что именно смотреть»), resource titles with
#                                    commentary glued on (explanations belong in
#                                    note, title = the citable name), placeholder resource URLs
#                                    (example.com, fake video ids) left over from
#                                    authoring, url-less resources still waiting for a
#                                    real link (the curation queue — not an error), and
#                                    resources on registration/paywalled
#                                    domains (consultant.ru, garant.ru) that a reader
#                                    can't actually open for free
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

  desc "Flag mechanical content gaps: self-check, internal links, resource notes"
  task audit: :environment do
    # Emblems: an AI draft can invent a plausible name that has no file, and it can
    # fill every chapter with the same glyph. Both are silent in the UI.
    bad_icons = (Path.all.to_a + Course.all.to_a)
                .reject { |record| record.icon.blank? || Icon.emblem?(record.icon) }
    if bad_icons.any?
      puts "Неизвестные эмблемы (#{bad_icons.size}) — имени нет в наборе, см. content:icons:"
      bad_icons.each { |record| puts "  · #{record.slug}  →  #{record.icon}" }
    end

    Path.includes(:courses).find_each do |path|
      dupes = path.courses.map { it.icon }.compact_blank
                  .tally.select { |_icon, count| count > 1 }
      next if dupes.empty?

      puts "«#{path.title}»: эмблема повторяется у нескольких глав — одной из них она не нужна:"
      dupes.each { |icon, count| puts "  · #{icon} ×#{count}" }
    end

    missing = Lesson.where(kind: "lesson").select(&:missing_self_check?)

    if missing.empty?
      puts "✓ Все написанные теоретические уроки содержат блок самопроверки."
    else
      puts "Теория без вопросов для самопроверки (#{missing.size}) — стоит добавить:"
      missing.each { |lesson| puts "  · #{lesson.slug}  «#{lesson.title}»" }
    end

    # The wiki fabric: the authoring norm is 3–7 internal links per lesson;
    # zero means the lesson is not woven into the map at all. A link to a slug
    # that doesn't exist is a plain error.
    known_slugs = Lesson.pluck(:slug).to_set
    unlinked = Hash.new { |hash, key| hash[key] = [] }
    broken = []
    Lesson.includes(:path).find_each do |lesson|
      next unless lesson.has_body?

      links = lesson.linked_lesson_slugs
      unlinked[lesson.path.slug] << lesson.slug if links.empty?
      (links - known_slugs.to_a).each { |slug| broken << [ lesson.slug, slug ] }
    end

    if unlinked.empty?
      puts "✓ Все написанные уроки ссылаются на другие уроки."
    else
      puts "Уроки без единой внутренней ссылки (#{unlinked.values.sum(&:size)}) — вплетай в карту (норма 3–7 на урок):"
      unlinked.sort.each do |path_slug, slugs|
        puts "  #{path_slug} (#{slugs.size}):"
        slugs.each { |slug| puts "    · #{slug}" }
      end
    end

    if broken.any?
      puts "Внутренние ссылки в никуда (#{broken.size}) — битый slug, чинить обязательно:"
      broken.each { |lesson_slug, target| puts "  · #{lesson_slug} → /lessons/#{target}" }
    end

    # Internal links must carry the locale prefix. An unprefixed «/lessons/foo»
    # still WORKS (the app 301s it), which is exactly why nobody notices: every
    # such link costs the reader and the crawler a redirect. Seeds authored
    # before the prefix — and any new draft written from an old example — carry
    # the bare form; content:localize_links rewrites what is already in the DB.
    unprefixed = Hash.new { |hash, key| hash[key] = 0 }
    Lesson.includes(:path).find_each do |lesson|
      hits = [ lesson.body.to_s, lesson.task.to_s, lesson.description.to_s, lesson.rich_body&.body.to_s ]
             .join(" ").scan(%r{(?<!/ru)/lessons/[a-z0-9\-]+}).size
      unprefixed[lesson] = hits if hits.positive?
    end

    if unprefixed.empty?
      puts "✓ Все внутренние ссылки идут через /ru — лишних редиректов нет."
    else
      puts "Внутренние ссылки без префикса /ru (#{unprefixed.size} статей) — работают через 301, чинит content:localize_links:"
      unprefixed.sort_by { |lesson, _| lesson.slug }.each do |lesson, hits|
        puts "  · #{lesson.slug} (#{hits})"
      end
    end

    # The description does double duty: the line under the title AND the page's
    # <meta name="description">, which the view cuts at 160 characters. Past
    # that the snippet ends mid-word in search results — invisible on the site
    # itself, which is why it rots unnoticed. The authoring norm is ≤155.
    long_descriptions = (Path.all.to_a + Lesson.all.to_a)
                        .select { |record| record.description.to_s.length > 160 }
                        .sort_by { |record| -record.description.to_s.length }

    if long_descriptions.empty?
      puts "✓ Все описания влезают в поисковый сниппет (≤160 символов)."
    else
      puts "Описания длиннее 160 символов (#{long_descriptions.size}) — в сниппете обрежется на полуслове, норма ≤155:"
      long_descriptions.each do |record|
        puts "  · #{record.description.to_s.length}  #{record.slug}"
      end
    end

    # A callout is a blockquote whose first line is a marker from a small fixed
    # set (ApplicationHelper::CALLOUTS). An unknown or Latin-letter marker —
    # «[!ВНИМАНИЕ]», «[!TIP]» — silently renders as an ordinary grey quote:
    # the author sees text, just not the colour and label they meant.
    known_markers = ApplicationHelper::CALLOUTS.keys
    stray_markers = Hash.new { |hash, key| hash[key] = [] }
    Lesson.find_each do |lesson|
      [ lesson.body.to_s, lesson.task.to_s, lesson.rich_body&.body.to_s ].join(" ")
        .scan(/\[!([^\]\n]{1,30})\]/).flatten.uniq
        .reject { |marker| known_markers.include?(marker) }
        .each { |marker| stray_markers[marker] << lesson.slug }
    end

    if stray_markers.empty?
      puts "✓ Все маркеры выносок известны — каждая отрисуется цветным блоком."
    else
      puts "Неизвестные маркеры выносок (#{stray_markers.size}) — отрисуются серой цитатой, допустимы #{known_markers.join(", ")}:"
      stray_markers.sort.each do |marker, slugs|
        puts "  · [!#{marker}] — #{slugs.first(5).join(", ")}#{" …" if slugs.size > 5}"
      end
    end

    # Calculators are a Ruby registry (Calculator::ALL) that points at lessons
    # by slug — the one place where code hardcodes content. Rename or delete a
    # lesson in the admin and the «разобрано в статье» link just stops being
    # rendered: find_by returns nil and the view skips the block, no error.
    orphan_calculators = Calculator.all.select do |calculator|
      calculator.lesson_slug.present? && !Lesson.exists?(slug: calculator.lesson_slug)
    end

    if orphan_calculators.empty?
      puts "✓ Каждый калькулятор ссылается на существующую статью."
    else
      puts "Калькуляторы с битой привязкой к статье (#{orphan_calculators.size}) — ссылка тихо исчезла со страницы:"
      orphan_calculators.each do |calculator|
        puts "  · #{calculator.slug} → /lessons/#{calculator.lesson_slug}"
      end
    end

    # A required 400-page standard without a reader note («что именно смотреть»)
    # is an invitation to close the tab. Short-form kinds (video, article, tool)
    # don't need one — deliberately narrow.
    noteless = Resource.where(required: true, note: [ nil, "" ], kind: %w[norm document doc book])
                       .includes(:lesson).order(:lesson_id)

    if noteless.none?
      puts "✓ У всех обязательных документов есть заметка «что именно смотреть»."
    else
      puts "Обязательные документы без заметки читателю (#{noteless.size}) — добавь «что именно смотреть»:"
      noteless.each { |resource| puts "  · [#{resource.lesson&.slug}] «#{resource.title.to_s.truncate(70)}»" }
    end

    # A title is the source's citable NAME; explanations belong in `note`
    # (tools/AUTHOR_PROFESSION.md → «title = имя, note = объяснение»). Two
    # deliberately narrow smells, so legitimately long official ГОСТ/приказ
    # names are never flagged: (a) an editorial parenthetical — words like
    # «проверить»/«утратила силу» are instructions to the reader, never part
    # of an official name; (b) a software/tool title with a dash-glued
    # description — the brand name is short, the tail is a note.
    commentary = /\([^)]*(провер|актуальн|утратил|предыдущ|см\.)[^)]*\)/i
    padded = Resource.includes(:lesson).order(:lesson_id).select do |resource|
      resource.title.to_s.match?(commentary) ||
        (%w[software tool].include?(resource.kind) && resource.title.to_s.match?(/\s—\s/))
    end

    if padded.none?
      puts "✓ Названия ресурсов чистые — пояснения живут в note, а не в title."
    else
      puts "Пояснения, приклеенные к названию (#{padded.size}) — перенеси в note, title = только имя источника:"
      padded.each { |resource| puts "  · [#{resource.lesson&.slug}] #{resource.kind}  «#{resource.title.to_s.truncate(90)}»" }
    end

    # Placeholder URLs left over from authoring — the RFC 2606 reserved
    # documentation domains (example.com/.org/.net) and a fake YouTube video
    # id are both real "someone forgot to fill this in" smells, not real
    # sources. They must never reach a public lesson.
    placeholder = Resource.where(
      "url LIKE '%example.com%' OR url LIKE '%example.org%' OR url LIKE '%example.net%' " \
      "OR url LIKE '%watch?v=example%'"
    ).includes(:lesson).order(:lesson_id)

    if placeholder.none?
      puts "✓ Заглушечных ссылок (example.com и фейковых video id) не найдено."
    else
      puts "Заглушечные ссылки (#{placeholder.size}) — замени на реальный источник или удали ресурс:"
      placeholder.each { |resource| puts "  · [#{resource.lesson&.slug}] #{resource.url}  «#{resource.title.to_s.truncate(70)}»" }
    end

    # Resources with no URL are VALID and intentional: authoring leaves a norm/
    # book/doc as a name-only entry (rendered non-clickable) rather than inventing
    # a link — «качественная ссылка или никакой». This is not an error, it's the
    # curation queue: the list of document names still waiting for a real URL.
    urlless = Resource.where(url: [ nil, "" ]).includes(:lesson).order(:lesson_id)

    if urlless.none?
      puts "✓ Ресурсов без URL нет — у каждого либо реальная ссылка, либо он снят."
    else
      puts "Ресурсы без URL (#{urlless.size}) — названия ждут реальной ссылки (норма, не ошибка):"
      urlless.each { |resource| puts "  · [#{resource.lesson&.slug}] #{resource.kind}  «#{resource.title.to_s.truncate(70)}»" }
    end

    # consultant.ru and garant.ru show a real page (HTTP 200 — content:links
    # won't catch this) but gate the actual document text behind registration
    # or a paid subscription. Prefer, in order: publication.pravo.gov.ru
    # (законы, приказы — бесплатно и постоянно по закону), the issuing
    # agency's own site (fstec.ru, profstandart.rosmintrud.ru), protect.gost.ru
    # (ГОСТ), docs.cntd.ru (норм. документы, обычно бесплатно). See the
    # 2026-07 link migration commit for a worked example of the mapping.
    paywalled = Resource.where("url LIKE '%consultant.ru%' OR url LIKE '%garant.ru%'")
                        .includes(:lesson).order(:lesson_id)

    if paywalled.none?
      puts "✓ Ссылок на consultant.ru/garant.ru (регистрация или платный доступ) не найдено."
    else
      puts "Ссылки на consultant.ru/garant.ru (#{paywalled.size}) — читатель не откроет без регистрации/оплаты, замени:"
      paywalled.each { |resource| puts "  · [#{resource.lesson&.slug}] #{resource.url}  «#{resource.title.to_s.truncate(70)}»" }
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
