module Admin
  class LessonSuggestionsController < BaseController
    before_action :set_suggestion, only: %i[show approve reject]

    def index
      @order = params[:order] == "asc" ? :asc : :desc
      @grouped = editable_suggestions.pending.includes(:lesson)
                                     .order(created_at: @order)
                                     .group_by(&:lesson)
    end

    def show
      @lesson = @suggestion.lesson
    end

    def approve
      return redirect_to admin_lesson_suggestions_path unless @suggestion.status == "pending"

      ActiveRecord::Base.transaction do
        @suggestion.lesson.revise!(
          section: @suggestion.section,
          html: @suggestion.proposed_html,
          editor_name: @suggestion.author_name,
          edit_reason: @suggestion.edit_reason,
          source: "suggestion",
          suggestion: @suggestion
        )
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
      authorize_path!(@suggestion.lesson)
    end
  end
end
