class IllustrationsController < ApplicationController
  allow_unauthenticated_access

  def index
    @paths = Path.published.localized.ordered
    # Fragment keys: a changed, added or removed lesson re-reads that profession's census.
    @touched_at = Lesson.where(path_id: @paths.map(&:id)).group(:path_id).maximum(:updated_at)
    @lesson_counts = Lesson.where(path_id: @paths.map(&:id)).group(:path_id).count
  end
end
