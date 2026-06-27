module Admin
  class LessonSuggestionsController < BaseController
    before_action :set_suggestion, only: %i[show approve reject]

    def index
      @order = sort_order
      @grouped = pending_grouped
    end

    def show
      @lesson = @suggestion.lesson
    end

    def approve
      if @suggestion.status == "pending"
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
          record_admin_action("suggestion_approved", target: @suggestion,
            lesson: @suggestion.lesson.title, section: @suggestion.section)
        end
      end
      respond_to_decision(I18n.t("flash.suggestion_approved"))
    end

    def reject
      if @suggestion.status == "pending"
        ActiveRecord::Base.transaction do
          @suggestion.update!(
            status: "rejected",
            reviewer_comment: params.dig(:lesson_suggestion, :reviewer_comment)
          )
          record_admin_action("suggestion_rejected", target: @suggestion,
            lesson: @suggestion.lesson.title, section: @suggestion.section)
        end
      end
      respond_to_decision(I18n.t("flash.suggestion_rejected"))
    end

    private

    def set_suggestion
      @suggestion = LessonSuggestion.find(params[:id])
      authorize_path!(@suggestion.lesson)
    end

    def sort_order
      params[:order] == "asc" ? :asc : :desc
    end

    def pending_grouped
      editable_suggestions.pending.includes(:lesson).order(created_at: @order).group_by(&:lesson)
    end

    # The decision came either from the queue's inline buttons (params[:inline] —
    # update the list in place via Turbo Stream, no reload) or from the review
    # page's forms (redirect back to the queue, as before). The no-JS fallback
    # also redirects.
    def respond_to_decision(notice)
      if params[:inline] && request.format.turbo_stream?
        flash.now[:notice] = notice
        @order = sort_order
        @grouped = pending_grouped
        render :decision
      else
        redirect_to admin_lesson_suggestions_path, notice: notice
      end
    end
  end
end
