class RevisionsController < ApplicationController
  allow_unauthenticated_access

  PER_PAGE = 10

  before_action :set_lesson

  # Reader-facing change history, loaded lazily into a Turbo Frame. Pagination is
  # cumulative — "show more" grows the limit so earlier rows stay on screen.
  def index
    @page = [ params[:page].to_i, 1 ].max
    @revisions = @lesson.lesson_revisions.ordered.limit(@page * PER_PAGE)
    @more = @lesson.lesson_revisions_count > @page * PER_PAGE
  end

  def show
    @revision = @lesson.lesson_revisions.find(params[:id])
  end

  private

  def set_lesson
    @lesson = Lesson.joins(:path)
                    .where(paths: { status: "published" })
                    .find_by!(slug: params[:lesson_slug])
  end
end
