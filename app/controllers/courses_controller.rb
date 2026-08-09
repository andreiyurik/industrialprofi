class CoursesController < ApplicationController
  allow_unauthenticated_access

  def show
    @course = Course.published
                    .joins(:path).where(paths: { status: "published" })
                    .find_by!(slug: params[:slug])
    @path = @course.path
    # Same one-locale-home rule as paths#show.
    unless @path.locale == params[:locale]
      return redirect_to course_path(@course, locale: @path.locale), status: :moved_permanently
    end

    @lessons = @course.lessons.to_a
    @lessons_by_stage = @lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for_course(@course) : Set.new
    @continue_lesson = if signed_in?
      @lessons.find { |lesson| !@completed_ids.include?(lesson.id) }
    else
      @lessons.first
    end
  end
end
