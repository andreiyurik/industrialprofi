class PathsController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress, only: :show

  def index
    # Signed-in landing on / goes straight to the dashboard; catalog stays reachable at /paths.
    return redirect_to dashboard_path if signed_in? && request.path == root_path

    @paths = Path.published.localized.ordered
    @course_counts = Path.published_course_counts
    @completed_counts = signed_in? ? Current.user.lesson_completions.joins(:lesson).group("lessons.path_id").count : {}

    # Gives a mid-path learner a way back to their direction before anything new competes.
    if signed_in? && (@focus_path = Current.user.focus_path)
      @focus_next_lesson = Current.user.next_lesson_in(@focus_path)
    end
  end

  # «Обзор» landing + chapter outline; the programme itself lives in
  # Paths::TheoriesController, with practice/dictionary/references as siblings.
  def show
    load_curriculum
  end
end
