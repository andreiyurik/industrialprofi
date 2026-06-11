class LessonCompletionsController < ApplicationController
  before_action :set_lesson

  def create
    Current.user.lesson_completions.create_or_find_by!(lesson: @lesson)
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
      @lesson = Lesson.joins(:path)
                      .where(paths: { status: "published" })
                      .find_by!(slug: params[:lesson_slug])
      @path = @lesson.path
    end

    def load_progress
      @lessons_by_stage = @path.lessons.group_by(&:stage)
      @completed_ids = Current.user.completed_lesson_ids_for(@path)
    end

    # The milestone moment: completing the last lesson of a stage (or the whole
    # path) deserves a louder cheer than a silent checkmark.
    def celebration_message
      if @path.lessons.all? { |lesson| @completed_ids.include?(lesson.id) }
        t(".path_completed", title: @path.title)
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
