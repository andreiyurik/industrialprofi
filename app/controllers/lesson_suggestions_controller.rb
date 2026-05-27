class LessonSuggestionsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create

  def new
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
    @section = %w[body task description].include?(params[:section]) ? params[:section] : "body"
    @suggestion = LessonSuggestion.new(lesson: @lesson, section: @section)
  end

  def create
    @lesson = Lesson.find(params[:lesson_suggestion][:lesson_id])
    @suggestion = @lesson.lesson_suggestions.new(suggestion_params)

    if @suggestion.save
      redirect_to lesson_path(@lesson), notice: I18n.t("flash.suggestion_submitted")
    else
      @section = @suggestion.section
      render :new, status: :unprocessable_entity
    end
  end

  private

  def suggestion_params
    params.require(:lesson_suggestion).permit(:section, :body_markdown, :author_name, :author_contact)
  end
end
