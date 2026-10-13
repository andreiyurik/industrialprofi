# Folded into a Feedback like the co-author application: the founder or an editor
# fetches the file and fills the slot, so a member never writes to the disk.
class IllustrationSuggestionsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to lesson_path(params[:lesson_slug]), alert: t("auth.rate_limited") }

  before_action :set_lesson

  FIELDS = %i[link note].freeze

  def new
    @suggestion = { brief: params[:brief] }
  end

  def create
    @suggestion = suggestion_params.to_h.symbolize_keys.transform_values { |value| value.to_s.truncate(1000) }

    if @suggestion[:link].blank?
      flash.now[:alert] = t("illustration_suggestions.incomplete")
      return render :new, status: :unprocessable_entity
    end

    body = Feedback.compose_message(:illustration_suggestions, fields: [ :lesson, :brief, *FIELDS ],
      values: @suggestion.merge(lesson: "#{@lesson.title} — #{lesson_url(@lesson)}"))
    feedback = Current.user.feedbacks.create!(body: body, page_url: lesson_path(@lesson))
    FeedbackMailer.new_message(feedback).deliver_later
    redirect_to lesson_path(@lesson), notice: t("illustration_suggestions.sent", email: Current.user.email_address)
  end

  private
    def set_lesson
      @lesson = Lesson.joins(:path).merge(Path.published).find_by!(slug: params[:lesson_slug])
    end

    def suggestion_params
      params.expect(illustration_suggestion: [ :brief, *FIELDS ])
    end
end
