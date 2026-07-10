# Owns the FTS5 side of lesson search: keeping lesson_search_index in sync
# (Lesson calls index/remove from its commit callbacks) and querying it. The
# virtual table has no ActiveRecord model — all FTS SQL lives behind this PORO.
class LessonSearch
  LIMIT = 25
  SNIPPET_WORDS = 20
  # bm25 weights per indexed column (title, description, body, lesson_id):
  # a title hit should easily outrank a passing mention deep in a body.
  RANKING = "bm25(lesson_search_index, 8.0, 4.0, 1.0, 0.0)"

  Result = Data.define(:lesson, :snippet)

  class << self
    def index(lesson)
      remove(lesson.id)
      connection.execute(sanitize(<<~SQL, lesson.id, lesson.title, *indexable_sections(lesson)))
        INSERT INTO lesson_search_index (lesson_id, title, description, body)
        VALUES (?, ?, ?, ?)
      SQL
    end

    def remove(lesson_id)
      connection.execute(sanitize("DELETE FROM lesson_search_index WHERE lesson_id = ?", lesson_id))
    end

    def rebuild
      connection.execute("DELETE FROM lesson_search_index")
      Lesson.with_all_rich_text.find_each { |lesson| index(lesson) }
      Lesson.count
    end

    def sanitize(sql, *values)
      ActiveRecord::Base.sanitize_sql_array([ sql, *values ])
    end

    def connection = ActiveRecord::Base.connection

    private
      # A section's searchable text is what the reader sees: rich text when a
      # human has edited it, the markdown column otherwise. Task rides in the
      # body column — nobody searches "the task", they search the words.
      def indexable_sections(lesson)
        [ section_text(lesson, :description),
          [ section_text(lesson, :body), section_text(lesson, :task) ].compact_blank.join("\n\n") ]
      end

      def section_text(lesson, section)
        rich = lesson.public_send(:"rich_#{section}")
        rich.present? ? rich.to_plain_text : strip_markdown(lesson.public_send(section))
      end

      # Snippets come straight from the indexed text, so markdown syntax would
      # leak into search results as noise ("## Что ты поймёшь…").
      def strip_markdown(text)
        text.to_s
            .gsub(/!\[[^\]]*\]\([^)]*\)/, " ")
            .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
            .gsub(/^#+\s+/, "")
            .gsub(/[*_`>|]/, " ")
            .squeeze(" ")
      end
  end

  def initialize(query)
    @query = query.to_s.strip
  end

  def results
    return [] if match_expression.blank?

    rows = self.class.connection.select_all(self.class.sanitize(<<~SQL, match_expression))
      SELECT lesson_search_index.lesson_id AS lesson_id,
             snippet(lesson_search_index, 2, '<mark>', '</mark>', '…', #{SNIPPET_WORDS}) AS snippet
      FROM lesson_search_index
      JOIN lessons ON lessons.id = lesson_search_index.lesson_id
      JOIN courses ON courses.id = lessons.course_id AND courses.status = 'published'
      JOIN paths   ON paths.id   = lessons.path_id   AND paths.status = 'published'
      WHERE lesson_search_index MATCH ?
      ORDER BY #{RANKING}
      LIMIT #{LIMIT}
    SQL

    lessons = Lesson.where(id: rows.map { |row| row["lesson_id"] })
                    .includes(:course, :path).index_by(&:id)
    rows.filter_map do |row|
      lesson = lessons[row["lesson_id"]]
      Result.new(lesson: lesson, snippet: row["snippet"]) if lesson
    end
  end

  private
    # User input becomes a safe FTS5 expression: bare words only, each quoted
    # (so FTS operators like NEAR/OR/- are inert) and prefix-matched — the
    # closest cheap fit for Russian morphology (кабел* → кабель/кабеля/…).
    def match_expression
      @query.scan(/\p{Word}+/).first(8).map { |term| %("#{term}"*) }.join(" ")
    end
end
