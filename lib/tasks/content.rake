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
#                                    pointing at a slug that doesn't exist, required
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

  # One-off migration of the old code-side dictionary (config/glossary.yml,
  # keyed by profession slug, each entry naming its lesson) into GlossaryTerm rows
  # owned by those lessons. Idempotent: a term already on its lesson is skipped.
  # The six electrician entries that named no lesson get the one that explains
  # them. Run once per database after deploying the glossary_terms table; the
  # YAML and this task go away afterwards.
  # Rouge 5 ships its own IEC 61131-3 lexer under `iecst`, so our Structured
  # Text lexer (which claimed Smalltalk's `st`) is gone; lesson markdown written
  # as ```st must say ```iecst or Rouge colours it as Smalltalk. Pristine rows
  # are re-stamped so the importer still sees them as its own. Run once per
  # database; this task goes away afterwards.
  desc "Rename ```st code fences to ```iecst in lesson markdown (one-off)"
  task st_to_iecst: :environment do
    fence = /^```st[ \t]*$/
    changed = 0
    Lesson.where("body LIKE '%```st%' OR task LIKE '%```st%'").find_each do |lesson|
      pristine = !lesson.frozen_for_import?
      lesson.body = lesson.body.to_s.gsub(fence, "```iecst")
      lesson.task = lesson.task.to_s.gsub(fence, "```iecst") if lesson.task.present?
      next unless lesson.changed?

      lesson.stamp_import!(lesson.origin) if pristine
      lesson.save!
      changed += 1
    end
    puts "lessons: #{changed} renamed to ```iecst."
  end

  desc "Move config/glossary.yml into lesson-owned glossary terms (one-off)"
  task glossary_from_yaml: :environment do
    file = Rails.root.join("config/glossary.yml")
    abort "#{file} is gone — nothing to migrate" unless file.exist?

    homeless = {
      "ГОСТ" => "01-chto-takoe-pue", "СНиП" => "01-chto-takoe-pue", "СП" => "01-chto-takoe-pue",
      "ВЛ" => "02-sposoby-prokladki", "КЛ" => "02-sposoby-prokladki", "ЛЭП" => "02-sposoby-prokladki"
    }
    created = skipped = 0
    missing = []

    YAML.load_file(file).each do |path_slug, entries|
      entries.each do |entry|
        lesson_slug = entry["lesson"] || homeless[entry["term"]]
        lesson = Lesson.find_by(slug: lesson_slug)
        next missing << "#{path_slug}/#{entry["term"]} → #{lesson_slug.inspect}" unless lesson

        term = lesson.glossary_terms.find_or_initialize_by(abbr: entry["term"])
        next skipped += 1 if term.persisted?

        term.update!(full: entry["full"], note: entry["note"], analog: entry["analog"], origin: "seed")
        created += 1
      end
    end

    puts "glossary terms: #{created} created, #{skipped} already present."
    puts "no lesson found for: #{missing.join(', ')}" if missing.any?
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
