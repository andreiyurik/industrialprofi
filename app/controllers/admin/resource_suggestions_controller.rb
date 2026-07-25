module Admin
  # The reader-proposed-sources queue. Editors of a profession see its lessons'
  # link suggestions; approving turns one into a real Resource on the lesson,
  # rejecting closes it. The moderation surface mirrors LessonSuggestions, but a
  # link is structured, so it lives in its own small model and queue.
  class ResourceSuggestionsController < BaseController
    before_action :set_suggestion, only: %i[approve reject]

    def index
      @grouped = editable_resource_suggestions.pending
                   .includes(lesson: :path).order(created_at: :desc).group_by(&:lesson)
    end

    def approve
      if @suggestion.pending?
        ActiveRecord::Base.transaction do
          resource = @suggestion.into_resource!
          @suggestion.update!(status: "approved", reviewed_at: Time.current)
          record_admin_action("resource_suggestion_approved", target: @suggestion,
            lesson: @suggestion.lesson.title, resource: resource.title)
        end
      end
      redirect_to admin_resource_suggestions_path, notice: t("flash.resource_suggestion_approved")
    end

    def reject
      if @suggestion.pending?
        ActiveRecord::Base.transaction do
          @suggestion.update!(status: "rejected", reviewed_at: Time.current,
            reviewer_comment: params.dig(:resource_suggestion, :reviewer_comment))
          record_admin_action("resource_suggestion_rejected", target: @suggestion,
            lesson: @suggestion.lesson.title, source: @suggestion.title)
        end
      end
      redirect_to admin_resource_suggestions_path, notice: t("flash.resource_suggestion_rejected")
    end

    private

    def set_suggestion
      @suggestion = ResourceSuggestion.find(params[:id])
      authorize_path!(@suggestion.lesson)
    end

    def editable_resource_suggestions
      Current.user.reviewable_resource_suggestions
    end
  end
end
