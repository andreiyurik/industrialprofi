module Admin
  # The founder's control room: who is signing up, what needs review, is the
  # disk safe. Plain group/count queries — cheap at this scale; the seam for
  # later is Rails.cache.fetch (Solid Cache), not a stats table.
  class DashboardController < BaseController
    before_action :ensure_can_administer

    SIGNUP_CHART_WEEKS = 12

    def show
      @users_total = User.count
      @users_week = User.where(created_at: 7.days.ago..).count
      @users_month = User.where(created_at: 30.days.ago..).count
      @active_week = active_user_count_since(7.days.ago)

      @pending_suggestions = LessonSuggestion.pending.count

      @completions_total = LessonCompletion.count
      @completions_week = LessonCompletion.where(created_at: 7.days.ago..).count
      @journal_entries_total = JournalEntry.count
      @storage_bytes = ActiveStorage::Blob.sum(:byte_size)

      @paths_published = Path.published.count
      @paths_total = Path.count
      @courses_total = Course.count
      @lessons_total = Lesson.count

      @signups_by_week = signups_by_week(SIGNUP_CHART_WEEKS)
      @recent_users = User.order(created_at: :desc).limit(10)
    end

    private
      # "Active" = did real work (completed a lesson or wrote a journal entry),
      # same definition as the user-facing heatmap. Logins don't count.
      def active_user_count_since(time)
        (LessonCompletion.where(created_at: time..).distinct.pluck(:user_id) |
          JournalEntry.where(created_at: time..).distinct.pluck(:user_id)).size
      end

      # [[week_start_date, signups], ...] oldest → newest, zero-filled.
      def signups_by_week(weeks)
        from = (weeks - 1).weeks.ago.to_date.beginning_of_week
        daily = User.where(created_at: from.beginning_of_day..).group("DATE(created_at)").count
                    .transform_keys { |day| Date.parse(day.to_s) }
        (0...weeks).map do |i|
          start = from + (i * 7)
          [ start, daily.sum { |day, count| day.between?(start, start + 6) ? count : 0 } ]
        end
      end
  end
end
