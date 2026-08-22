require "yaml"

# Parses ONE pasted profession (a single YAML document — path → courses →
# sections → lessons → resources) and imports it through the same create-or-refresh
# safety as the seed importer, but stamped origin "ai" and forced to DRAFT:
# AI scaffolds breadth, a human verifies and publishes later via the trust ladder.
# A human-frozen row (origin "human" or carrying a revision) is skipped, so a paste
# can never overwrite an expert's work; a pristine AI draft IS refreshed in place
# (that is how AI deepens its own stubs). A slug that already belongs to ANOTHER
# profession is refused, not silently re-parented (see ImportUpsert).
#
# `plan` runs the exact same code as `import!` inside a rolled-back transaction,
# so the preview can never disagree with what the commit does.
class CurriculumDocument
  include ImportUpsert

  SOURCE = "ai"
  # Room for a full profession arriving as a pack (CurriculumPack re-serializes
  # the tree into this document), not just a pasted draft.
  MAX_BYTES = 2.megabytes

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
      @seen = Set.new

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
    rescue ImportUpsert::ImportConflict => e
      @errors << e.message
      nil
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.record.errors.full_messages.to_sentence
      nil
    end

    def upsert_path(author, counts)
      data = @data["path"]
      path = Path.find_or_initialize_by(slug: lookup_slug(Path, data))
      attrs = { title: data["title"], description: data["description"] }
      attrs[:landing] = Path.normalize_landing(data["landing"]) if data.key?("landing")
      status = upsert(path, counts, :paths, attrs) do
        path.author_id = author.id
        path.icon = emblem(data["icon"])
        path.status = "draft"
        path.position = (Path.maximum(:position) || 0) + 1
      end
      [ path, node("path", path.title, status) ]
    end

    def upsert_course(path, data, counts)
      course = Course.find_or_initialize_by(slug: lookup_slug(Course, data))
      status = upsert(course, counts, :courses,
                      { path: path, title: data["title"], description: data["description"] },
                      target_path: path) do
        course.icon = emblem(data["icon"])
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
                      { course: course, stage: stage, title: data["title"],
                        description: data["description"], body: data["body"], task: data["task"],
                        kind: data["kind"].presence || "lesson",
                        difficulty: lesson_difficulty(data),
                        position: lesson.new_record? ? position : lesson.position },
                      target_path: course.path)

      unless status == :exists
        children = lesson.import_children(resources: data["resources"], terms: data["terms"], source: SOURCE)
        counts[:resources] += children["resources_created"]
      end
      lesson_nodes << node("lesson", lesson.title, status)
      position
    end

    # Maps the shared create-or-refresh (ImportUpsert) onto the preview tree's
    # status vocabulary (:new / :updated / :exists) and counts everything the
    # import would write (created or refreshed, but not the frozen rows it skips).
    # Same rule as the seed importer: create-only, and an emblem the pack names but
    # we don't have is dropped rather than refused — the row then inherits.
    def emblem(name)
      name.presence && Icon.emblem?(name) ? name : nil
    end

    def upsert(record, counts, table, attrs, target_path: nil, &create_defaults)
      claim_slug!(@seen, record) unless record.is_a?(Path)
      result = import_upsert(record, SOURCE, attrs, target_path: target_path, &create_defaults)
      counts[table] += 1 if %i[created updated].include?(result)
      { created: :new, updated: :updated, unchanged: :unchanged, frozen: :exists }.fetch(result)
    end

    def lookup_slug(klass, data)
      data["slug"].presence || klass.slugify(data["title"].to_s)
    end

    # Theory lessons carry no difficulty; a practice lesson defaults to beginner.
    def lesson_difficulty(data)
      return nil unless (data["kind"].presence || "lesson") == "practice"

      data["difficulty"].presence || "beginner"
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
