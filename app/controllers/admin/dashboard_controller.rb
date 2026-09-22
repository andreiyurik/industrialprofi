module Admin
  class DashboardController < AdministratorController
    CHART_WEEKS = 12

    GOALS = {
      users_total: 1_000,
      paths_published: 12,
      active_week: 100
    }.freeze

    def show
      @users_total = User.count
      @users_week = User.where(created_at: 7.days.ago..).count
      @users_month = User.where(created_at: 30.days.ago..).count
      @active_week = User.active_count_since(7.days.ago)

      @pending_suggestions = LessonSuggestion.pending.count

      @editorship_candidates = TrackRecord.editorship_candidates

      @coauthor_applications = Feedback.coauthor_applications.where(created_at: 30.days.ago..).count

      @pending_review = Path.where(status: "pending_review").count +
                        Course.where(status: "pending_review").count

      # Verification expired here means the map already fell back to stage 3.
      @verifications_expired = Path.published.verification_expired.count

      @completions_total = LessonCompletion.count
      @completions_week = LessonCompletion.where(created_at: 7.days.ago..).count
      @journal_entries_total = JournalEntry.count

      @paths_published = Path.published.count
      @paths_total = Path.count
      @paths_with_editor = Editorship.count_published_paths_with_editor
      @courses_total = Course.count
      @lessons_total = Lesson.count

      @top_bookmarked_lessons = Lesson.top_bookmarked(10)

      @signups_by_week = WeeklyCounts.for(User.all, weeks: CHART_WEEKS)
      @completions_by_week = WeeklyCounts.for(LessonCompletion.all, weeks: CHART_WEEKS)
      @recent_users = User.order(created_at: :desc).limit(10)

      current_by_goal = { users_total: @users_total, paths_published: @paths_published, active_week: @active_week }
      @goals = GOALS.map do |key, target|
        current = current_by_goal.fetch(key)
        { key:, target:, current:, achieved: current >= target }
      end
    end

    def vitals
      @status = SystemStatus.new
      @emails_week = MailMetrics.sent_last(7)
      render layout: false
    end
  end
end
