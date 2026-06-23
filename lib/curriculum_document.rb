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
      existing = data["slug"].present? ? Path.find_by(slug: data["slug"]) : nil
      return [ existing, node("path", existing.title, :exists) ] if existing

      path = Path.new(title: data["title"], description: data["description"], status: "draft")
      path.slug = data["slug"] if data["slug"].present?
      path.author_id = author.id
      path.position = (Path.maximum(:position) || 0) + 1
      path.stamp_import!(SOURCE)
      path.save!
      counts[:paths] += 1
      [ path, node("path", path.title, :new) ]
    end

    def upsert_course(path, data, counts)
      existing = data["slug"].present? ? Course.find_by(slug: data["slug"]) : nil
      return [ existing, node("course", existing.title, :exists) ] if existing

      course = Course.new(path:, title: data["title"], description: data["description"], status: "draft")
      course.slug = data["slug"] if data["slug"].present?
      course.position = (path.courses.maximum(:position) || 0) + 1
      course.stamp_import!(SOURCE)
      course.save!
      counts[:courses] += 1
      [ course, node("course", course.title, :new) ]
    end

    def upsert_lesson(course, stage, data, position, counts, lesson_nodes)
      slug = data["slug"].presence
      # When the paste omits a slug, look up by the slug we'd generate from the
      # title, so re-importing the same document reuses the lesson instead of
      # silently creating a "-2" duplicate. A typed slug is honoured as-is.
      lookup = slug || Lesson.slugify(data["title"])
      if lookup.present? && Lesson.exists?(slug: lookup)
        lesson_nodes << node("lesson", data["title"], :exists)
        return position
      end

      position += 1
      lesson = Lesson.new(
        course:, stage:, title: data["title"], description: data["description"],
        body: data["body"], task: data["task"], kind: data["kind"].presence || "lesson",
        position:
      )
      lesson.slug = slug if slug
      lesson.difficulty = data["difficulty"].presence || "beginner" if lesson.practice?
      lesson.stamp_import!(SOURCE)
      lesson.save!
      counts[:lessons] += 1
      import_resources(lesson, data["resources"], counts)
      lesson_nodes << node("lesson", lesson.title, :new)
      position
    end

    def import_resources(lesson, resources, counts)
      Array(resources).each_with_index do |data, index|
        resource = lesson.resources.build(
          title: data["title"], url: data["url"], kind: data["kind"].presence || "document",
          required: data.fetch("required", false), position: index + 1
        )
        resource.origin = SOURCE
        resource.save!
        counts[:resources] += 1
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
