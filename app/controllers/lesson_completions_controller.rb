class LessonCompletionsController < ApplicationController
  before_action :set_lesson

  def create
    Current.user.lesson_completions.create_or_find_by!(lesson: @lesson)
    respond
  end

  def destroy
    Current.user.lesson_completions.destroy_by(lesson: @lesson)
    respond
  end

  private
    def set_lesson
      @lesson = Lesson.joins(:path)
                      .where(paths: { status: "published" })
                      .find_by!(slug: params[:lesson_slug])
      @path = @lesson.path
    end

    def respond
      respond_to do |format|
        format.turbo_stream do
          @lessons_by_stage = @path.lessons.group_by(&:stage)
          @completed_ids = Current.user.completed_lesson_ids_for(@path)
        end
        format.html { redirect_to lesson_path(@lesson) }
      end
    end
end
