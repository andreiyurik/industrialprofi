module Admin
  class LessonSuggestionsController < BaseController
    before_action :set_suggestion, only: %i[show approve reject]

    def index
      @suggestions = LessonSuggestion.pending.includes(:lesson).order(created_at: :desc)
    end

    def show
      @lesson = @suggestion.lesson
    end

    def approve
      return redirect_to admin_lesson_suggestions_path unless @suggestion.status == "pending"

      ActiveRecord::Base.transaction do
        @suggestion.lesson.update!(@suggestion.section => @suggestion.body_markdown)
        @suggestion.update!(status: "approved")
      end
      redirect_to admin_lesson_suggestions_path, notice: I18n.t("flash.suggestion_approved")
    end

    def reject
      return redirect_to admin_lesson_suggestions_path unless @suggestion.status == "pending"

      @suggestion.update!(
        status: "rejected",
        reviewer_comment: params.dig(:lesson_suggestion, :reviewer_comment)
      )
      redirect_to admin_lesson_suggestions_path, notice: I18n.t("flash.suggestion_rejected")
    end

    private

    def set_suggestion
      @suggestion = LessonSuggestion.find(params[:id])
    end
  end
end
