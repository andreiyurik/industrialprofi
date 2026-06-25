require "yaml"

# Parses ONE pasted profession (a single YAML document — path → courses →
# sections → lessons → resources) and imports it through the same create-only
# safety as the seed importer, but stamped origin "ai" and forced to DRAFT:
# AI scaffolds breadth, a human verifies and publishes later via the trust
# ladder. It NEVER touches an existing row — anything whose slug already exists
# is skipped, so a paste can't overwrite live or human-owned content.
#
# `plan` runs the exact same code as `import!` inside a rolled-back transaction,
# so the preview can never disagree with what the commit does.
class CurriculumDocument
  include ImportUpsert

  SOURCE = "ai"
  MAX_BYTES = 512_000

  Result = Struct.new(:path_node, :course_nodes, :counts, :path, keyword_init: true)

  attr_reader :errors

  def self.parse(yaml_string) = new(yaml_string)

  def initialize(yaml_string)
    @raw = yaml_string.to_s
    @errors = []
    @data = load_yaml
    validate if @errors.empty?
  end

  def valid? = @errors.empty?

  def plan(author:)   = run(author:, dry_run: true)
  def import!(author:) = run(author:, dry_run: false)

  private
    def load_yaml
      return (@errors << :blank) && nil if @raw.blank?
      return (@errors << :too_large) && nil if @raw.bytesize > MAX_BYTES

      YAML.safe_load(@raw)
    rescue Psych::SyntaxError => e
      @errors << "YAML: #{e.message}"
      nil
    end

    def validate
      unless @data.is_a?(Hash) && @data["path"].is_a?(Hash)
        @errors << :no_path
        return
      end
      @errors << :no_path_title if @data.dig("path", "title").blank?
      courses = @data["courses"]
      @errors << :no_courses unless courses.is_a?(Array) && courses.any?
    end

    def run(author:, dry_run:)
      counts = Hash.new(0)
      course_nodes = []
      path = nil
      path_node = nil

      ActiveRecord::Base.transaction do
        path, path_node = upsert_path(author, counts)
        position = path.lessons.maximum(:position) || 0

        Array(@data["courses"]).each do |course_data|
          course, course_node = upsert_course(path, course_data, counts)
          course_node[:lessons] = []
          normalized_lessons(course_data).each do |stage, lesson_data|
            position = upsert_lesson(course, stage, lesson_data, position, counts, course_node[:lessons])
          end
          course_nodes << course_node
        end

        raise ActiveRecord::Rollback if dry_run
      end

      Result.new(path_node:, course_nodes:, counts:, path:)
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.record.errors.full_messages.to_sentence
      nil
    end

    def upsert_path(author, counts)
      data = @data["path"]
      path = Path.find_or_initialize_by(slug: lookup_slug(Path, data))
      status = upsert(path, counts, :paths,
                      title: data["title"], description: data["description"]) do
        path.author_id = author.id
        path.status = "draft"
        path.position = (Path.maximum(:position) || 0) + 1
      end
      [ path, node("path", path.title, status) ]
    end

    def upsert_course(path, data, counts)
      course = Course.find_or_initialize_by(slug: lookup_slug(Course, data))
      status = upsert(course, counts, :courses,
                      path: path, title: data["title"], description: data["description"]) do
        course.status = "draft"
        course.position = (path.courses.maximum(:position) || 0) + 1
      end
      [ course, node("course", course.title, status) ]
    end

    # A slug-less lesson is matched by its title-derived slug, so re-import reuses
    # the row instead of creating a "-2" duplicate. Only a NEW lesson takes a
    # fresh appended position; an existing one keeps its global position.
    def upsert_lesson(course, stage, data, position, counts, lesson_nodes)
      lesson = Lesson.find_or_initialize_by(slug: lookup_slug(Lesson, data))
      position += 1 if lesson.new_record?

      status = upsert(lesson, counts, :lessons,
                      course: course, stage: stage, title: data["title"],
                      description: data["description"], body: data["body"], task: data["task"],
                      kind: data["kind"].presence || "lesson",
                      difficulty: lesson_difficulty(data),
                      position: lesson.new_record? ? position : lesson.position)

      import_resources(lesson, data["resources"], counts) unless status == :exists
      lesson_nodes << node("lesson", lesson.title, status)
      position
    end

    # Maps the shared create-or-refresh (ImportUpsert) onto the preview tree's
    # status vocabulary (:new / :updated / :exists) and counts everything the
    # import would write (created or refreshed, but not the frozen rows it skips).
    def upsert(record, counts, table, attrs, &create_defaults)
      result = import_upsert(record, SOURCE, attrs, &create_defaults)
      counts[table] += 1 unless result == :frozen
      { created: :new, updated: :updated, unchanged: :updated, frozen: :exists }.fetch(result)
    end

    def lookup_slug(klass, data)
      data["slug"].presence || klass.slugify(data["title"].to_s)
    end

    # Theory lessons carry no difficulty; a practice lesson defaults to beginner.
    def lesson_difficulty(data)
      return nil unless (data["kind"].presence || "lesson") == "practice"

      data["difficulty"].presence || "beginner"
    end

    # Resources ride with the lesson, keyed by title so re-import refreshes them
    # in place instead of duplicating. A resource a human edited is left alone.
    def import_resources(lesson, resources, counts)
      Array(resources).each_with_index do |data, index|
        resource = lesson.resources.find_or_initialize_by(title: data["title"])
        next if resource.persisted? && resource.origin == "human"

        was_new = resource.new_record?
        resource.assign_attributes(
          url: data["url"], kind: data["kind"].presence || "document",
          required: data.fetch("required", false), position: index + 1
        )
        resource.origin = SOURCE if was_new
        next unless resource.changed?

        resource.save!
        counts[:resources] += 1 if was_new
      end
    end

    # Lessons may be nested under sections (section title → stage) or listed
    # directly under the course (each carrying its own optional stage).
    def normalized_lessons(course_data)
      if course_data["sections"].is_a?(Array)
        course_data["sections"].flat_map do |section|
          Array(section["lessons"]).map { |lesson| [ section["title"], lesson ] }
        end
      else
        Array(course_data["lessons"]).map { |lesson| [ lesson["stage"], lesson ] }
      end
    end

    def node(kind, title, status) = { kind:, title:, status: }
end
