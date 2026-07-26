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

    # Save-for-later queue, newest first — any lesson, not just practice.
    @bookmarked_lessons = Current.user.lesson_bookmarks
                                 .includes(lesson: :path)
                                 .order(created_at: :desc)
                                 .map(&:lesson)

    # «Мои правки»: the contributor's feedback loop — proposed text edits AND
    # proposed sources, newest-decision first. Rendering them here closes the
    # loop, so the outcome email (SuggestionEmailsJob) is never sent to someone
    # who already saw it. Both ride one seen-timestamp; capture it before the
    # visit marks everything seen, so a fresh decision still gets its dot now.
    # Capture the seen-timestamp before the visit marks everything seen, so a
    # fresh decision still gets its per-row dot now; the touch (below) then
    # clears the header dot and lets the outcome email be skipped.
    @seen_before = Current.user.suggestions_seen_at
    @my_contributions = my_contributions
    Current.user.touch(:suggestions_seen_at) if Current.user.unseen_suggestion_outcomes?
  end

  private

  def my_contributions
    (Current.user.lesson_suggestions.includes(:lesson).to_a +
     Current.user.resource_suggestions.includes(:lesson).to_a)
      .sort_by { |contribution| contribution.reviewed_at || contribution.created_at }
      .reverse.first(6)
  end
end
