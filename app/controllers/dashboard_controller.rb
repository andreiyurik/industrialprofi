class DashboardController < ApplicationController
  def show
    @started_paths = Current.user.started_paths.includes(:lessons, :courses)
    # Reuse the started path so its eager loads aren't wasted.
    focus = Current.user.focus_path
    @focus_path = @started_paths.detect { |path| path == focus } || focus
    @other_paths = @started_paths.reject { |path| path == @focus_path }
    @completed_ids_by_path = @started_paths.index_with { |path| Current.user.completed_lesson_ids_for(path) }

    @suggested_paths = @started_paths.any? ? [] : Path.published.official.localized.ordered.limit(3)

    @activity_since = 15.weeks.ago.to_date.beginning_of_week
    @activity = Current.user.activity_by_day(since: @activity_since)

    @bookmarked_lessons = Current.user.lesson_bookmarks
                                 .includes(lesson: :path)
                                 .order(created_at: :desc)
                                 .map(&:lesson)

    @map = Current.user.map
    @followed_maps = Current.user.followed_maps.readable.includes(:user).to_a
    @completed_ids = Current.user.completed_lesson_ids if @followed_maps.any?

    # Must run before the touch below marks everything seen.
    @seen_before = Current.user.suggestions_seen_at
    @my_contributions = my_contributions
    Current.user.touch(:suggestions_seen_at) if Current.user.unseen_suggestion_outcomes?

    @trust_progress = trust_progress
  end

  private

  def trust_progress
    return unless Current.user.member? && @my_contributions.any?
    TrackRecord.for(Current.user).accepted_by_profession.max_by(&:last)
  end

  def my_contributions
    (Current.user.lesson_suggestions.includes(:lesson).to_a +
     Current.user.resource_suggestions.includes(:lesson).to_a)
      .sort_by { |contribution| contribution.reviewed_at || contribution.created_at }
      .reverse.first(6)
  end
end
