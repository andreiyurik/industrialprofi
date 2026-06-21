class LessonsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lesson = Lesson.joins(course: :path)
                    .where(courses: { status: "published" }, paths: { status: "published" })
                    .includes(:resources, :course, :path)
                    .find_by!(slug: params[:slug])
    @course = @lesson.course
    @path = @lesson.path
    # Sidebar is scoped to the current course (TOP-style course contents).
    @lessons_by_stage = @course.lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for_course(@course) : Set.new

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end
end
