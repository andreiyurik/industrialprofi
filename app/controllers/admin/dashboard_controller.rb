module Admin
  # The founder's control room: who is signing up, what needs review, is the
  # disk safe. Plain group/count queries — cheap at this scale; the seam for
  # later is Rails.cache.fetch (Solid Cache), not a stats table.
  class DashboardController < AdministratorController
    CHART_WEEKS = 12

    def show
      @users_total = User.count
      @users_week = User.where(created_at: 7.days.ago..).count
      @users_month = User.where(created_at: 30.days.ago..).count
      @active_week = User.active_count_since(7.days.ago)

      @pending_suggestions = LessonSuggestion.pending.count

      # Contributors whose accepted edits earned an editorship proposal — the
      # system surfaces them so discovery doesn't hinge on the founder's memory.
      @editorship_candidates = TrackRecord.editorship_candidates

      # Practitioners asking to lead a profession (from /contribute) — a recent
      # count so the founder never has to dig them out of the general inbox.
      @coauthor_applications = Feedback.coauthor_applications.where(created_at: 30.days.ago..).count

      # Editors flip finished drafts to pending_review and wait for the founder —
      # surface that queue here so the signal doesn't depend on a personal email.
      @pending_review = Path.where(status: "pending_review").count +
                        Course.where(status: "pending_review").count

      # Expert marks past their shelf life (Path::Maturity::VERIFICATION_TTL) —
      # the founder nudges the curator; the map already fell back to stage 3.
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

      # Acquisition (signups) next to engagement (lesson completions) — the two
      # together answer "are people arriving AND actually learning?".
      @signups_by_week = WeeklyCounts.for(User.all, weeks: CHART_WEEKS)
      @completions_by_week = WeeklyCounts.for(LessonCompletion.all, weeks: CHART_WEEKS)
      @recent_users = User.order(created_at: :desc).limit(10)
    end

    # Lazy-loaded fragment (loading: :lazy frame). Holds the VPS vital signs —
    # the `df` shell-out + Solid Queue probes — so the dashboard shell paints
    # immediately and these stream in a beat later.
    def vitals
      @status = SystemStatus.new
      @emails_week = MailMetrics.sent_last(7)
      render layout: false
    end
  end
end
