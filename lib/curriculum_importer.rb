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
  DEFAULT_DIR = Rails.root.join("db/seeds/curriculum")

  def self.run(...) = new(...).run

  def initialize(dir: DEFAULT_DIR, source: "seed", io: $stdout)
    @dir = Pathname(dir)
    @source = source
    @io = io
    @counts = Hash.new(0)
  end

  def run
    Dir.glob(@dir.join("*/path.yml")).sort.each { |path_yml| import_path(path_yml) }
    reset_counters
    report
    @counts
  end

  # Parse one lesson .md file into the attributes a Lesson needs: frontmatter +
  # WHY (description) + body + the "## Задание" task block.
  def self.parse_lesson(file_path)
    content = File.read(file_path)
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
    def import_path(path_yml)
      meta = YAML.safe_load_file(path_yml)
      path = Path.find_or_initialize_by(slug: File.basename(File.dirname(path_yml)))
      upsert(path,
             title: meta["title"], description: meta["description"],
             position: meta["position"], status: meta["status"])

      position = 0 # lesson position is GLOBAL within the path (continuous prev/next)
      Dir.glob(File.join(File.dirname(path_yml), "*/course.yml")).sort.each do |course_yml|
        position = import_course(course_yml, path, position)
      end
    end

    def import_course(course_yml, path, position)
      meta = YAML.safe_load_file(course_yml)
      course = Course.find_or_initialize_by(slug: meta["slug"])
      upsert(course,
             path: path, title: meta["title"], description: meta["description"],
             position: meta["position"], status: meta["status"] || "published")

      Dir.glob(File.join(File.dirname(course_yml), "*/section.yml")).sort.each do |section_yml|
        stage = YAML.safe_load_file(section_yml)["title"]
        Dir.glob(File.join(File.dirname(section_yml), "*.md")).sort.each do |md_file|
          position += 1
          import_lesson(md_file, course, path, stage, position)
        end
      end
      position
    end

    def import_lesson(md_file, course, path, stage, position)
      data = self.class.parse_lesson(md_file)
      lesson = Lesson.find_or_initialize_by(slug: File.basename(md_file, ".md"))
      applied = upsert(lesson,
                       course: course, path: path, stage: stage,
                       title: data["title"], description: data["description"],
                       body: data["body"], task: data["task"], position: position,
                       kind: data["kind"] || "lesson",
                       difficulty: data["difficulty"] || (data["kind"] == "practice" ? "beginner" : nil))

      # Resources ride with the lesson: only sync them while the lesson is still
      # importer-owned. Once it's frozen, its resources belong to the editor.
      import_resources(lesson, data["resources"]) if applied
    end

    def import_resources(lesson, resources)
      Array(resources).each_with_index do |res, i|
        resource = lesson.resources.find_or_initialize_by(title: res["title"])
        next if resource.persisted? && resource.origin == "human"

        resource.assign_attributes(
          url: res["url"], kind: res["kind"], required: res.fetch("required", false),
          country_code: res["country_code"], position: i + 1
        )
        if resource.new_record?
          resource.origin = @source
          resource.save!
          @counts["resources_created"] += 1
        elsif resource.changed?
          resource.save!
          @counts["resources_updated"] += 1
        end
      end
    end

    # Returns true when the row was applied (created or refreshed), false when it
    # was frozen and left untouched.
    def upsert(record, attrs)
      table = record.class.model_name.collection

      if record.new_record?
        record.assign_attributes(attrs)
        record.stamp_import!(@source)
        record.save!
        @counts["#{table}_created"] += 1
        true
      elsif record.frozen_for_import?
        @counts["#{table}_frozen"] += 1
        false
      else
        record.assign_attributes(attrs)
        record.stamp_import!(@source)
        if record.changed?
          record.save!
          @counts["#{table}_updated"] += 1
        end
        true
      end
    end

    # Counter caches are kept exact regardless of the create/update/skip mix.
    def reset_counters
      Course.find_each { |course| Course.reset_counters(course.id, :lessons) }
      Path.find_each   { |path| Path.reset_counters(path.id, :courses, :lessons) }
    end

    def report
      @io.puts "Curriculum import complete (source: #{@source})."
      %w[paths courses lessons resources].each do |table|
        @io.puts "  #{table}: " \
                 "+#{@counts["#{table}_created"]} new, " \
                 "#{@counts["#{table}_updated"]} refreshed, " \
                 "#{@counts["#{table}_frozen"]} frozen (human-owned)."
      end
      @io.puts "  totals: #{Path.count} paths, #{Course.count} courses, " \
               "#{Lesson.count} lessons, #{Resource.count} resources."
    end
end
