class PathsController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress, only: :show

  def index
    # Like The Odin Project: a signed-in user landing on "/" goes straight to
    # their dashboard; the catalog stays reachable at /paths.
    return redirect_to dashboard_path if signed_in? && request.path == root_path

    @paths = Path.published.localized.ordered
    @course_counts = Path.published_course_counts
    @completed_counts = signed_in? ? Current.user.lesson_completions.joins(:lesson).group("lessons.path_id").count : {}

    # A learner browsing the catalog mid-path gets a way back to their
    # direction before anything new competes for attention.
    if signed_in? && (@focus_path = Current.user.focus_path)
      @focus_next_lesson = Current.user.next_lesson_in(@focus_path)
    end
  end

  # The hub's «Обзор»: the landing (what the profession is) plus the chapter
  # outline, under the shared header. The programme itself is the «Теория» tab
  # (Paths::TheoriesController); practice, dictionary and reference shelf are
  # its siblings.
  def show
    load_curriculum
  end
end
