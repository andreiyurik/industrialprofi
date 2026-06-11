class ProjectsController < ApplicationController
  allow_unauthenticated_access

  def index
    @focus_path = signed_in? ? Current.user.focus_path : nil
    @paths = Path.localized.where(status: "published")
                 .joins(:lessons).merge(Lesson.practice).distinct.order(:position)

    @selected_path = @paths.find { |path| path.slug == params[:path] }
    @selected_difficulty = params[:difficulty].presence_in(Lesson::DIFFICULTIES)
    @saved_only = signed_in? && params[:saved] == "1"

    scope = Lesson.practice.joins(:path)
                  .where(paths: { status: "published" })
                  .merge(Path.localized)
                  .includes(:path)
    scope = scope.where(path: @selected_path) if @selected_path
    scope = scope.where(difficulty: @selected_difficulty) if @selected_difficulty
    scope = scope.where(id: Current.user.lesson_bookmarks.select(:lesson_id)) if @saved_only

    # Focus profession first (defaults, not walls); within a path the lesson
    # position is already the easy→hard curriculum ladder.
    @lessons = scope.sort_by do |lesson|
      [ lesson.path == @focus_path ? 0 : 1, lesson.path.position, lesson.position ]
    end
    @completed_ids = signed_in? ? Current.user.lesson_completions.pluck(:lesson_id).to_set : Set.new
    @bookmarked_ids = signed_in? ? Current.user.lesson_bookmarks.pluck(:lesson_id).to_set : Set.new
  end
end
