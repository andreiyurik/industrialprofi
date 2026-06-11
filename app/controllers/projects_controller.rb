class ProjectsController < ApplicationController
  allow_unauthenticated_access

  def index
    @lessons_by_path = Lesson.joins(:path)
                             .where(kind: "practice", paths: { status: "published" })
                             .merge(Path.localized)
                             .includes(:path)
                             .order("paths.position", :position)
                             .group_by(&:path)
    @completed_ids = signed_in? ? Current.user.lesson_completions.pluck(:lesson_id).to_set : Set.new
  end
end
