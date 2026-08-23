class ProjectsController < ApplicationController
  allow_unauthenticated_access

  def index
    @focus_path = signed_in? ? Current.user.focus_path : nil
    @paths = Path.localized.where(status: "published")
                 .joins(:lessons).merge(Lesson.practice).distinct.order(:position)

    # One profession's tasks live on its hub now (the «Практика» tab, grouped
    # by level — so only the saved-view rides along); old ?path= links 301
    # there. An unknown slug is just ignored, as any bad filter value is.
    if (selected_path = @paths.find { |path| path.slug == params[:path] })
      return redirect_to path_practice_path(selected_path, saved: params[:saved].presence), status: :moved_permanently
    end

    @selected_difficulty = params[:difficulty].presence_in(Lesson::DIFFICULTIES)
    @saved_only = signed_in? && params[:saved] == "1"

    scope = Lesson.practice.joins(:path)
                  .where(paths: { status: "published" })
                  .merge(Path.localized)
                  .includes(:path)
    scope = scope.where(difficulty: @selected_difficulty) if @selected_difficulty
    scope = scope.where(id: Current.user.lesson_bookmarks.select(:lesson_id)) if @saved_only

    # Anonymous pages carry no personal state (no completions, no bookmarks),
    # so crawlers and repeat visitors revalidate instead of re-rendering —
    # same contract as lessons#show. The count guards against deletions,
    # which don't move max(updated_at).
    if Current.user.nil?
      last_change = [ scope.maximum(:updated_at), @paths.maximum(:updated_at) ].compact.max
      fresh_when etag: [ scope.count, last_change ], last_modified: last_change
      return if performed?
    end

    # The page reads as a document — one section per profession, focus
    # profession first (defaults, not walls); within a group the lesson
    # position is already the easy→hard curriculum ladder.
    @lessons_by_path = scope.group_by(&:path)
                            .sort_by { |path, _| [ path == @focus_path ? 0 : 1, path.position ] }
                            .map { |path, lessons| [ path, lessons.sort_by(&:position) ] }
    @found_count = @lessons_by_path.sum { |_, lessons| lessons.size }
    @total_tasks = Lesson.practice.joins(:path).where(paths: { status: "published" })
                         .merge(Path.localized).count
    @completed_ids = signed_in? ? Current.user.lesson_completions.pluck(:lesson_id).to_set : Set.new
    @bookmarked_ids = signed_in? ? Current.user.lesson_bookmarks.pluck(:lesson_id).to_set : Set.new
  end
end
