module Admin
  class LessonSuggestionsController < BaseController
    def index
      @suggestions = LessonSuggestion.pending.includes(:lesson).order(created_at: :desc)
    end

    def show
      @suggestion = LessonSuggestion.find(params[:id])
      @lesson = @suggestion.lesson
    end

    def approve
      @suggestion = LessonSuggestion.find(params[:id])
      @suggestion.lesson.update!(@suggestion.section => @suggestion.body_markdown)
      @suggestion.update!(status: "approved")
      redirect_to admin_lesson_suggestions_path, notice: I18n.t("flash.suggestion_approved")
    end

    def reject
      @suggestion = LessonSuggestion.find(params[:id])
      @suggestion.update!(
        status: "rejected",
        reviewer_comment: params.dig(:lesson_suggestion, :reviewer_comment)
      )
      redirect_to admin_lesson_suggestions_path, notice: I18n.t("flash.suggestion_rejected")
    end
  end
end
