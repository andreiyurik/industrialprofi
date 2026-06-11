class ProjectsController < ApplicationController
  allow_unauthenticated_access

  def index
    @focus_path = signed_in? ? Current.user.focus_path : nil
    @lessons_by_path = Lesson.joins(:path)
                             .where(kind: "practice", paths: { status: "published" })
                             .merge(Path.localized)
                             .includes(:path)
                             .order("paths.position", :position)
                             .group_by(&:path)
                             .sort_by { |path, _| [ path == @focus_path ? 0 : 1, path.position ] }
                             .to_h
    @completed_ids = signed_in? ? Current.user.lesson_completions.pluck(:lesson_id).to_set : Set.new
  end
end
