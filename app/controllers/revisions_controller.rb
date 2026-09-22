class RevisionsController < ApplicationController
  allow_unauthenticated_access

  PER_PAGE = 20

  before_action :set_lesson

  # Keyset pagination on version (descending): показать ещё appends via Turbo Stream, so
  # existing rows are never re-queried — light whether a lesson has 5 revisions or 5000.
  def index
    scope = @lesson.lesson_revisions.ordered
    scope = scope.where("version < ?", params[:before]) if params[:before].present?

    @revisions, @more = paginate_window(scope, per_page: PER_PAGE)
    @next_cursor = @revisions.last&.version

    # Credits source contributors, who have no revision row of their own.
    @credited_sources = @lesson.resources.where.not(contributor_name: [ nil, "" ]).order(:created_at)

    # Last date already on screen, so the append can skip a duplicate day heading.
    @boundary_date = parse_date(params[:d])

    respond_to do |format|
      format.html
      format.turbo_stream
    end
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

  def parse_date(value)
    Date.iso8601(value) if value.present?
  rescue ArgumentError
    nil
  end
end
