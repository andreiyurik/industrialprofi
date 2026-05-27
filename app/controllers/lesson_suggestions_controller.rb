class LessonSuggestionsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create

  def new
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
    @section = %w[body task description].include?(params[:section]) ? params[:section] : "body"
    @suggestion = LessonSuggestion.new(lesson: @lesson, section: @section)
  end

  def create
    @suggestion = LessonSuggestion.new(suggestion_params)
    @lesson = @suggestion.lesson

    if @suggestion.save
      redirect_to lesson_path(@lesson), notice: I18n.t("flash.suggestion_submitted")
    else
      @section = @suggestion.section
      render :new, status: :unprocessable_entity
    end
  end

  private

  def suggestion_params
    params.require(:lesson_suggestion).permit(:lesson_id, :section, :body_markdown, :author_name, :author_contact)
  end
end
