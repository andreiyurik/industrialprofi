module Admin
  # The founder's control room: who is signing up, what needs review, is the
  # disk safe. Plain group/count queries — cheap at this scale; the seam for
  # later is Rails.cache.fetch (Solid Cache), not a stats table.
  class DashboardController < BaseController
    before_action :ensure_can_administer

    CHART_WEEKS = 12

    def show
      @users_total = User.count
      @users_week = User.where(created_at: 7.days.ago..).count
      @users_month = User.where(created_at: 30.days.ago..).count
      @active_week = active_user_count_since(7.days.ago)

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

      @completions_total = LessonCompletion.count
      @completions_week = LessonCompletion.where(created_at: 7.days.ago..).count
      @journal_entries_total = JournalEntry.count

      @paths_published = Path.published.count
      @paths_total = Path.count
      # The self-sufficiency compass: published professions maintained by
      # someone besides the founder. Grants count only while an active editor
      # role backs them — the same rule can_edit_path? applies.
      @paths_with_editor = Editorship.joins(:user)
        .merge(User.active.where(role: :editor))
        .where(path_id: Path.published.select(:id))
        .distinct.count(:path_id)
      @courses_total = Course.count
      @lessons_total = Lesson.count

      # What readers actually want to keep — the save-for-later signal, ranked.
      # An inner join naturally drops anything with zero bookmarks.
      @top_bookmarked_lessons = Lesson.joins(:lesson_bookmarks)
        .select("lessons.*, COUNT(lesson_bookmarks.id) AS bookmarks_count")
        .group("lessons.id")
        .order(Arel.sql("COUNT(lesson_bookmarks.id) DESC"))
        .limit(10)

      # Acquisition (signups) next to engagement (lesson completions) — the two
      # together answer "are people arriving AND actually learning?".
      @signups_by_week = weekly_counts(User.all, CHART_WEEKS)
      @completions_by_week = weekly_counts(LessonCompletion.all, CHART_WEEKS)
      @recent_users = User.order(created_at: :desc).limit(10)
    end

    # Lazy-loaded fragment (loading: :lazy frame). Holds the VPS vital signs —
    # the `df` shell-out + Solid Queue probes — so the dashboard shell paints
    # immediately and these stream in a beat later.
    def vitals
      # Disk safety + background-job health — the one-server VPS's vital signs.
      @status = SystemStatus.new
      # "Is mail flowing?" — registration is hard-gated on a working SMTP.
      @emails_week = MailMetrics.sent_last(7)
      render layout: false
    end

    private
      # "Active" = did real work (completed a lesson or wrote a journal entry),
      # same definition as the user-facing heatmap. Logins don't count.
      def active_user_count_since(time)
        (LessonCompletion.where(created_at: time..).distinct.pluck(:user_id) |
          JournalEntry.where(created_at: time..).distinct.pluck(:user_id)).size
      end

      # [[week_start_date, count], ...] oldest → newest, zero-filled. `scope` is
      # any relation with a created_at (User, LessonCompletion, …).
      def weekly_counts(scope, weeks)
        from = (weeks - 1).weeks.ago.to_date.beginning_of_week
        daily = scope.where(created_at: from.beginning_of_day..).group("DATE(created_at)").count
                     .transform_keys { |day| Date.parse(day.to_s) }
        (0...weeks).map do |i|
          start = from + (i * 7)
          [ start, daily.sum { |day, count| day.between?(start, start + 6) ? count : 0 } ]
        end
      end
  end
end
