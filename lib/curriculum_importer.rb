require "yaml"

# Walks the YAML/Markdown curriculum tree and upserts it into the database.
#
#   <path>/path.yml
#   <path>/<NN>-<course>/course.yml
#   <path>/<NN>-<course>/<MM>-<section>/section.yml   (title → lesson.stage)
#   <path>/<NN>-<course>/<MM>-<section>/<lesson>.md
#
# The database is the source of truth — this is a CREATE-ONLY feed. It creates
# missing rows and refreshes rows that are still pristine (importer-owned and
# unchanged by a human); any row a human authored or has since edited is frozen
# (see Importable) and skipped, so a re-import can never overwrite human work.
#
# Freezing is per row, not per subtree: a frozen (e.g. published) path is still
# walked, so new lessons added to the YAML still import beneath it.
class CurriculumImporter
  include ImportUpsert

  DEFAULT_DIR = Rails.root.join("db/seeds/curriculum")

  def self.run(...) = new(...).run

  def initialize(dir: DEFAULT_DIR, source: "seed", io: $stdout, only: nil)
    @dir = Pathname(dir)
    @source = source
    @io = io
    @only = only.presence # a profession slug, or nil to import the whole tree
    @counts = Hash.new(0)
    @icon_warnings = []
  end

  def run
    ymls = path_ymls
    if @only && ymls.empty?
      @io.puts "Профессия «#{@only}» не найдена: нет #{@dir.join(@only, 'path.yml')}."
      return @counts
    end

    # Each profession imports all-or-nothing: a conflict (duplicate/cross-path slug)
    # rolls back that profession instead of leaving half of it written.
    ymls.each { |path_yml| ActiveRecord::Base.transaction { import_path(path_yml) } }
    reset_counters
    report
    @counts
  end

  # Parse one lesson .md file into the attributes a Lesson needs: frontmatter +
  # WHY (description) + body + the "## Задание" task block.
  def self.parse_lesson(file_path)
    parse_lesson_content(File.read(file_path))
  end

  # Same parse from a string — for lessons arriving inside a pack (CurriculumPack)
  # rather than from disk.
  def self.parse_lesson_content(content)
    frontmatter, body = content.split(/^---\s*$/, 3).reject(&:blank?)

    meta = YAML.safe_load(frontmatter, permitted_classes: [ Symbol ])
    description, rest = body.split(/^---\s*$/, 2).map { |part| part&.strip }

    if rest.to_s.match?(/^## Задание/m)
      body_text, task = rest.split(/^## Задание\s*$/m, 2).map { |part| part&.strip }
    else
      body_text = rest.presence
      task = nil
    end

    meta.merge("description" => description, "body" => body_text, "task" => task)
  end

  private
    def path_ymls
      pattern = @only ? @dir.join(@only, "path.yml") : @dir.join("*/path.yml")
      Dir.glob(pattern).sort
    end

    # New content defaults to draft; the founder publishes deliberately (sets
    # status: published in the yml and re-seeds, or publishes via admin). An
    # explicit status in the yml is always honored.
    def import_path(path_yml)
      # Per-profession slug ledger: a duplicate WITHIN a profession raises here;
      # a slug owned by ANOTHER profession is caught by the cross-path guard.
      @seen = Set.new
      meta = YAML.safe_load_file(path_yml)
      path = Path.find_or_initialize_by(slug: File.basename(File.dirname(path_yml)))
      attrs = {
        title: meta["title"], description: meta["description"],
        position: meta["position"], status: meta["status"].presence || "draft"
      }
      # landing.yml rides with path.yml as one more importable field — refreshed
      # while the profession is pristine, frozen with it once an expert edits.
      landing_yml = File.join(File.dirname(path_yml), "landing.yml")
      attrs[:landing] = Path.normalize_landing(YAML.safe_load_file(landing_yml)) if File.exist?(landing_yml)
      upsert(path, attrs) { path.icon = emblem(meta["icon"], path.slug) }
      attach_cover(path, File.dirname(path_yml))

      position = 0 # lesson position is GLOBAL within the path (continuous prev/next)
      Dir.glob(File.join(File.dirname(path_yml), "*/course.yml")).sort.each do |course_yml|
        position = import_course(course_yml, path, position)
      end
    end

    # cover.{jpg,jpeg,png,webp} next to path.yml — attached once, never
    # replaced (an expert's later choice in the admin wins, like the emblem).
    def attach_cover(path, dir)
      return if path.cover.attached?

      file = Dir.glob(File.join(dir, "cover.{jpg,jpeg,png,webp}")).first or return
      path.cover.attach(io: File.open(file), filename: File.basename(file),
                        content_type: Marcel::MimeType.for(Pathname(file)))
      path.save!
      @counts["covers_attached"] += 1
    end

    def import_course(course_yml, path, position)
      meta = YAML.safe_load_file(course_yml)
      course = Course.find_or_initialize_by(slug: meta["slug"])
      upsert(course, {
               path: path, title: meta["title"], description: meta["description"],
               position: meta["position"], status: meta["status"].presence || "draft"
             }, target_path: path) { course.icon = emblem(meta["icon"], course.slug) }

      Dir.glob(File.join(File.dirname(course_yml), "*/section.yml")).sort.each do |section_yml|
        stage = YAML.safe_load_file(section_yml)["title"]
        lessons_in_section(section_yml).each do |md_file|
          position += 1
          import_lesson(md_file, course, path, stage, position)
        end
      end
      position
    end

    # Within a section, a lesson's own declared `position:` decides reading
    # order — NOT the filename. Falls back to filename (alphabetical) when a
    # file omits `position:`, so older content without it still imports
    # deterministically. Filenames stay free-form (readable slugs, not forced
    # into NN- prefixes) without silently scrambling the course.
    def lessons_in_section(section_yml)
      Dir.glob(File.join(File.dirname(section_yml), "*.md")).sort.sort_by do |md_file|
        [ lesson_frontmatter_position(md_file) || Float::INFINITY, md_file ]
      end
    end

    def lesson_frontmatter_position(md_file)
      frontmatter = File.read(md_file).split(/^---\s*$/, 3)[1]
      YAML.safe_load(frontmatter, permitted_classes: [ Symbol ])["position"]
    end

    def import_lesson(md_file, course, path, stage, position)
      data = self.class.parse_lesson(md_file)
      lesson = Lesson.find_or_initialize_by(slug: File.basename(md_file, ".md"))
      applied = upsert(lesson, {
                         course: course, path: path, stage: stage,
                         title: data["title"], description: data["description"],
                         body: data["body"], task: data["task"], position: position,
                         kind: data["kind"] || "lesson",
                         difficulty: data["difficulty"] || (data["kind"] == "practice" ? "beginner" : nil)
                       }, target_path: path)

      # Resources and abbreviations ride with the lesson: only sync them while the
      # lesson is still importer-owned. Once it's frozen, they belong to the editor.
      if applied
        lesson.import_children(resources: data["resources"], terms: data["terms"], source: @source)
              .each { |key, n| @counts[key] += n }
      end
    end

    # Maps the shared create-or-refresh (ImportUpsert) onto the report's
    # per-category counts. Returns true when the row was applied (created or
    # refreshed), false when frozen and left untouched (so the caller skips its
    # resources — once frozen, those belong to the editor).
    def upsert(record, attrs, target_path: nil, &create_defaults)
      claim_slug!(@seen, record) unless record.is_a?(Path)
      table = record.class.model_name.collection
      result = import_upsert(record, @source, attrs, target_path: target_path, &create_defaults)
      @counts["#{table}_#{result}"] += 1 unless result == :unchanged
      result != :frozen
    end

    # The emblem is a create-only default, NOT an importable field: a re-import must
    # never overwrite the glyph an expert picked in the admin, and picking one must
    # not freeze the row from legitimate content refreshes. It also stays out of
    # `import_digest` for that reason.
    #
    # An AI draft can confidently name an emblem that has no file. That's cosmetic,
    # so we drop it (the row then inherits) and say so — failing a 60-lesson import
    # over a glyph name would be absurd, but silence would ship it wrong.
    def emblem(name, slug)
      return nil if name.blank?
      return name if Icon.emblem?(name)

      @icon_warnings << "#{slug}: «#{name}»"
      nil
    end

    # Counter caches are kept exact regardless of the create/update/skip mix.
    def reset_counters
      Course.find_each { |course| Course.reset_counters(course.id, :lessons) }
      Path.find_each   { |path| Path.reset_counters(path.id, :courses, :lessons) }
    end

    def report
      @io.puts "Curriculum import complete (source: #{@source})."
      %w[paths courses lessons resources glossary_terms].each do |table|
        @io.puts "  #{table}: " \
                 "+#{@counts["#{table}_created"]} new, " \
                 "#{@counts["#{table}_updated"]} refreshed, " \
                 "#{@counts["#{table}_frozen"]} frozen (human-owned)."
      end
      @io.puts "  totals: #{Path.count} paths, #{Course.count} courses, " \
               "#{Lesson.count} lessons, #{Resource.count} resources, #{GlossaryTerm.count} terms."

      return if @icon_warnings.empty?

      @io.puts "  Неизвестные эмблемы — пропущены, запись наследует (см. bin/rails content:icons):"
      @icon_warnings.each { |warning| @io.puts "    ! #{warning}" }
    end
end
