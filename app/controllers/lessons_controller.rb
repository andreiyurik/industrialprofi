class LessonsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lesson = Lesson.joins(:path)
                    .where(paths: { status: "published" })
                    .includes(:resources, :path)
                    .find_by!(slug: params[:slug])
    @path = @lesson.path
    @lessons_by_stage = @path.lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for(@path) : Set.new

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end
end
