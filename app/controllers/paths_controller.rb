class PathsController < ApplicationController
  allow_unauthenticated_access

  def index
    # Like The Odin Project: a signed-in user landing on "/" goes straight to
    # their dashboard; the catalog stays reachable at /paths.
    return redirect_to dashboard_path if signed_in? && request.path == root_path

    @paths = Path.listable.localized.ordered
    @completed_counts = signed_in? ? Current.user.lesson_completions.joins(:lesson).group("lessons.path_id").count : {}

    # A learner browsing the catalog mid-path gets a way back to their
    # direction before anything new competes for attention.
    if signed_in? && (@focus_path = Current.user.focus_path)
      @focus_next_lesson = Current.user.next_lesson_in(@focus_path)
    end
  end

  def show
    @path = Path.published.find_by!(slug: params[:slug])
    @lessons = @path.lessons.to_a
    @lessons_by_stage = @lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for(@path) : Set.new
    @continue_lesson = signed_in? ? Current.user.next_lesson_in(@path) : @lessons.first
  end
end
