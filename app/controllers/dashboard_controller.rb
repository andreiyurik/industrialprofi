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

    # «Мои правки»: the contributor's feedback loop. Fresh decisions sort to
    # the top; rendering them here closes the loop, so the outcome email
    # (SuggestionEmailsJob) is never sent to someone who saw it in the app.
    @my_suggestions = Current.user.lesson_suggestions
                             .includes(:lesson)
                             .order(Arel.sql("COALESCE(reviewed_at, created_at) DESC"))
                             .limit(5)
    @fresh_suggestion_ids = fresh_suggestion_ids
    Current.user.touch(:suggestions_seen_at) if @fresh_suggestion_ids.any?
  end

  private

  def fresh_suggestion_ids
    scope = Current.user.lesson_suggestions.decided.where.not(reviewed_at: nil)
    if (seen_at = Current.user.suggestions_seen_at)
      scope = scope.where("reviewed_at > ?", seen_at)
    end
    scope.pluck(:id).to_set
  end
end
