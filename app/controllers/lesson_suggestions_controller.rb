class LessonSuggestionsController < ApplicationController
  # Suggesting an edit requires an account: real identity makes attribution
  # trustworthy and lets good contributors be promoted up the trust ladder.
  # Signed-out visitors hit the default require_authentication gate, which
  # stashes the return URL and brings them back to the form after signing in.
  rate_limit to: 5, within: 1.hour, only: :create

  def new
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])
    @section = %w[body task description].include?(params[:section]) ? params[:section] : "body"
    @suggestion = LessonSuggestion.new(lesson: @lesson, section: @section)
    prepopulate_rich_body
  end

  def create
    @lesson = Lesson.find_by!(slug: params[:lesson_slug])

    # Honeypot: bots fill the hidden "company" field — pretend success, save nothing.
    if params[:company].present?
      redirect_to lesson_path(@lesson), notice: I18n.t("flash.suggestion_submitted")
      return
    end

    @suggestion = @lesson.lesson_suggestions.new(suggestion_params)
    @suggestion.user = Current.user
    @suggestion.author_name = Current.user.name
    capture_base_content

    if @suggestion.save
      redirect_to lesson_path(@lesson), notice: I18n.t("flash.suggestion_submitted")
    else
      @section = %w[body task description].include?(@suggestion.section) ? @suggestion.section : "body"
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Snapshot the section as it stood when the edit was submitted, so the
  # moderator can be warned later if the lesson moved on in the meantime.
  def capture_base_content
    return unless LessonRevision::SECTIONS.include?(@suggestion.section)

    @suggestion.base_content = @lesson.section_html(@suggestion.section)
  end

  def prepopulate_rich_body
    rich_field = :"rich_#{@section}"
    if @lesson.send(rich_field).present?
      @suggestion.rich_body = @lesson.send(rich_field).body
    elsif @lesson.send(@section).present?
      @suggestion.rich_body.body = helpers.markdown(@lesson.send(@section))
    end
  end

  def suggestion_params
    params.require(:lesson_suggestion).permit(:section, :body_markdown, :rich_body, :edit_reason)
  end
end
