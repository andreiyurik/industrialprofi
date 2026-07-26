require "yaml"

# The reverse of CurriculumImporter: writes one profession from the database
# back into the same YAML/Markdown tree the importer reads, so content
# round-trips — an on-prem instance gets a content pack, an outside expert can
# author offline, and the content outlives any single install.
#
#   <dir>/<path.slug>/path.yml
#   <dir>/<path.slug>/<NN>-<course.slug>/course.yml
#   <dir>/<path.slug>/<NN>-<course.slug>/<MM>-section/section.yml
#   <dir>/<path.slug>/<NN>-<course.slug>/<MM>-section/<lesson.slug>.md
#
# The importer orders lessons by filename WITHIN a section (filename = slug),
# so a section whose lessons were drag-reordered out of alphabetical order is
# split into consecutive section dirs sharing the same title — directory order
# then reproduces the exact lesson order on import.
class CurriculumExporter
  DEFAULT_DIR = Rails.root.join("tmp/export")

  def self.run(...) = new(...).run

  def initialize(path, dir: DEFAULT_DIR, io: $stdout)
    @path = path
    @dir = Pathname(dir)
    @io = io
  end

  def run
    root = @dir.join(@path.slug)
    root.rmtree if root.exist?
    root.mkpath

    # The pack manifest: a format version lets future importers refuse packs
    # they don't understand instead of half-reading them. The one place a
    # timestamp is allowed — everything else must export deterministically.
    write_yaml root.join("pack.yml"),
      meta(format: CurriculumPack::FORMAT, exported_at: Time.current.iso8601,
           courses: @path.courses.count, lessons: @path.lessons.count)

    write_yaml root.join("path.yml"),
      meta(title: @path.title, description: @path.description,
           position: @path.position, status: @path.status)

    @path.courses.order(:position).each.with_index(1) do |course, number|
      export_course(course, root, number)
    end

    @io.puts "Экспортировано в #{root}: #{@path.courses.count} курсов, #{@path.lessons.count} статей."
    root
  end

  private
    def export_course(course, root, number)
      dir = root.join(format("%02d-%s", number, course.slug))
      write_yaml dir.join("course.yml"),
        meta(slug: course.slug, title: course.title, description: course.description,
             position: course.position, status: course.status)

      sections(course).each.with_index(1) do |(stage, lessons), section_number|
        # Section dir names are ordinal only: the importer takes the title from
        # section.yml and Cyrillic doesn't parameterize into a useful slug.
        section_dir = dir.join(format("%02d-section", section_number))
        write_yaml section_dir.join("section.yml"), meta(title: stage)
        lessons.each { |lesson| write_lesson(section_dir, lesson) }
      end
    end

    # Contiguous same-stage runs whose slugs stay in ascending (filename) order —
    # each run becomes one section dir, so import re-derives the exact order.
    def sections(course)
      course.lessons.ordered.to_a
            .chunk_while { |a, b| a.stage == b.stage && b.slug > a.slug }
            .map { |lessons| [ lessons.first.stage, lessons ] }
    end

    def write_lesson(section_dir, lesson)
      front = meta(title: lesson.title)
      front["kind"] = lesson.kind if lesson.practice?
      front["difficulty"] = lesson.difficulty if lesson.practice?
      resources = lesson.resources.map { |resource| resource_meta(resource) }
      front["resources"] = resources if resources.any?

      section_dir.join("#{lesson.slug}.md").write(<<~FILE)
        #{front.to_yaml.strip}
        ---
        #{section_text(lesson, :description)}
        ---
        #{lesson_body(lesson)}
      FILE
    end

    def resource_meta(resource)
      meta(title: resource.title, url: resource.url, kind: resource.kind,
           required: (true if resource.required?), country_code: resource.country_code,
           language: resource.language, note: resource.note)
    end

    def lesson_body(lesson)
      body = section_text(lesson, :body)
      task = section_text(lesson, :task)
      task.present? ? "#{body}\n\n## Задание\n\n#{task}" : body
    end

    # What the reader currently sees: the markdown column, unless a human edit
    # superseded it with rich text — then the rich HTML is the truth (markdown
    # carries raw HTML through Kramdown intact, so a re-import renders the same).
    def section_text(lesson, section)
      rich = lesson.public_send(:"rich_#{section}")
      rich.present? ? rich.body.to_html.strip : lesson.public_send(section).to_s.strip
    end

    # to_yaml emits its own leading "---" line, which doubles as the
    # frontmatter opener in lesson files.
    def meta(attrs)
      attrs.transform_keys(&:to_s).compact
    end

    def write_yaml(file, attrs)
      file.dirname.mkpath
      file.write(attrs.to_yaml)
    end
end
