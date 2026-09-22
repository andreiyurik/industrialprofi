# No ActiveRecord model for the virtual table — all FTS SQL lives here.
class LessonSearch
  LIMIT = 25
  SNIPPET_WORDS = 20
  # bm25 weights (title, description, body) — a title hit should outrank a passing mention.
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
      def indexable_sections(lesson)
        [ section_text(lesson, :description),
          [ section_text(lesson, :body), section_text(lesson, :task) ].compact_blank.join("\n\n") ]
      end

      def section_text(lesson, section)
        rich = lesson.public_send(:"rich_#{section}")
        rich.present? ? rich.to_plain_text : strip_markdown(lesson.public_send(section))
      end

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
    # Each word quoted so FTS operators (NEAR/OR/-) stay inert; prefix-matched for morphology.
    def match_expression
      @query.scan(/\p{Word}+/).first(8).map { |term| %("#{term}"*) }.join(" ")
    end
end
