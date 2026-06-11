class LessonCompletionsController < ApplicationController
  before_action :set_lesson

  def create
    Current.user.lesson_completions.create_or_find_by!(lesson: @lesson)
    # Done means no longer "saved for later".
    Current.user.lesson_bookmarks.destroy_by(lesson: @lesson)
    load_progress
    @celebration = celebration_message
    respond
  end

  def destroy
    Current.user.lesson_completions.destroy_by(lesson: @lesson)
    load_progress
    respond
  end

  private
    def set_lesson
      @lesson = Lesson.joins(course: :path)
                      .where(courses: { status: "published" }, paths: { status: "published" })
                      .find_by!(slug: params[:lesson_slug])
      @course = @lesson.course
      @path = @lesson.path
    end

    def load_progress
      # Course-scoped, matching the lesson-page sidebar it re-renders.
      @lessons_by_stage = @course.lessons.group_by(&:stage)
      @completed_ids = Current.user.completed_lesson_ids_for_course(@course)
    end

    # The milestone moment: finishing the last lesson of a section, course, or
    # the whole profession deserves a louder cheer than a silent checkmark.
    # Ordered most-significant first.
    def celebration_message
      path_completed_ids = Current.user.completed_lesson_ids_for(@path)
      if @path.lessons.all? { |lesson| path_completed_ids.include?(lesson.id) }
        t(".path_completed", title: @path.title)
      elsif @course.lessons.all? { |lesson| @completed_ids.include?(lesson.id) }
        t(".course_completed", title: @course.title)
      elsif @lesson.stage.present? && @lessons_by_stage[@lesson.stage].all? { |lesson| @completed_ids.include?(lesson.id) }
        t(".stage_completed", stage: @lesson.stage)
      end
    end

    def respond
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to lesson_path(@lesson), notice: @celebration }
      end
    end
end
