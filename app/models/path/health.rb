class Path::Health
  STALLED_AFTER = 14.days

  def initialize(path)
    @path = path
  end

  def pending_suggestions = LessonSuggestion.pending.where(lesson: lessons).count
  def pending_sources = ResourceSuggestion.pending.where(lesson: lessons).count

  def illustration_census = @illustration_census ||= IllustrationCensus.new(@path)
  def illustration_briefs = illustration_census.briefs.size
  def lessons_without_sources = lessons.where.missing(:resources).count

  def learners = latest_ticks.size
  def active_learners = latest_ticks.values.count { |_, at| at > 7.days.ago }

  def stall
    lesson_id, count = latest_ticks.values
      .select { |_, at| at < STALLED_AFTER.ago }
      .map(&:first).tally.max_by(&:last)

    [ lessons.find(lesson_id), count ] if lesson_id
  end

  private
    def lessons = @path.lessons

    # Staff click through lessons while editing, so only members count as learners.
    def latest_ticks
      @latest_ticks ||= LessonCompletion.joins(:lesson, :user)
        .where(lessons: { path_id: @path.id }, users: { role: "member" })
        .order(:created_at)
        .pluck(:user_id, :lesson_id, "lesson_completions.created_at")
        .to_h { |user_id, lesson_id, at| [ user_id, [ lesson_id, at ] ] }
    end
end
