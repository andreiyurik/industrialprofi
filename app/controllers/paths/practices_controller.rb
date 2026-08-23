# The «Практика» tab of a profession hub: that profession's tasks as a ladder
# — one group per level (ученик → подмастерье → мастер), the same list the
# chapter page draws, under the hub header. /projects shows the same rows
# across all professions.
class Paths::PracticesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    @saved_only = signed_in? && params[:saved] == "1"

    scope = @path.lessons.practice.ordered
    scope = scope.where(id: Current.user.lesson_bookmarks.select(:lesson_id)) if @saved_only

    # Anonymous pages carry no personal state, so crawlers revalidate instead
    # of re-rendering — the /projects contract. The count guards deletions.
    if Current.user.nil?
      last_change = [ scope.maximum(:updated_at), @path.updated_at ].compact.max
      fresh_when etag: [ scope.count, last_change ], last_modified: last_change
      return if performed?
    end

    lessons = scope.to_a
    # Levels in climbing order; a level with no tasks isn't a rung.
    @groups = Lesson::DIFFICULTIES.filter_map do |difficulty|
      tasks = lessons.select { |lesson| lesson.difficulty == difficulty }
      [ difficulty, tasks ] if tasks.any?
    end
    @total_tasks = @path.lessons.practice.count
    @bookmarked_ids = signed_in? ? Current.user.lesson_bookmarks.pluck(:lesson_id).to_set : Set.new
  end
end
