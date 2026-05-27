class LessonSuggestionsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create

  def new
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
    @section = %w[body task description].include?(params[:section]) ? params[:section] : "body"
    @suggestion = LessonSuggestion.new(lesson: @lesson, section: @section)
    prepopulate_rich_body
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

  def prepopulate_rich_body
    rich_field = :"rich_#{@section}"
    if @lesson.send(rich_field).present?
      @suggestion.rich_body = @lesson.send(rich_field).body
    elsif @lesson.send(@section).present?
      @suggestion.rich_body.body = helpers.markdown(@lesson.send(@section))
    end
  end

  def suggestion_params
    params.require(:lesson_suggestion).permit(:section, :body_markdown, :author_name, :author_contact, :rich_body)
  end
end
