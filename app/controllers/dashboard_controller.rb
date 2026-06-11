class DashboardController < ApplicationController
  def show
    @focus_path = Current.user.focus_path
    @started_paths = Current.user.started_paths.includes(:lessons, :courses)
    @other_paths = @started_paths.reject { |path| path == @focus_path }
    @completed_ids_by_path = @started_paths.index_with { |path| Current.user.completed_lesson_ids_for(path) }

    # Attention guard: new directions are offered ONLY to someone who hasn't
    # started one — a learner mid-path sees their path, not a catalog.
    @suggested_paths = @started_paths.any? ? [] : Path.published.official.localized.ordered.limit(3)

    # 16 full weeks ending this week — a quarter fills up fast; a year of
    # empty cells would only demotivate a newcomer.
    @activity_since = 15.weeks.ago.to_date.beginning_of_week
    @activity = Current.user.activity_by_day(since: @activity_since)

    # Save-for-later queue, newest first (a practice task often waits for
    # tools or materials).
    @bookmarked_lessons = Current.user.lesson_bookmarks
                                 .includes(lesson: :path)
                                 .order(created_at: :desc)
                                 .map(&:lesson)
  end
end
