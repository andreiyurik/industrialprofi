module Admin
  class RevisionsController < BaseController
    before_action :set_lesson

    def index
      @revisions = @lesson.lesson_revisions.ordered
    end

    # Restore a past version's content as a brand-new revision — history is never
    # rewritten, only appended to.
    def rollback
      revision = @lesson.lesson_revisions.find(params[:id])
      @lesson.revise!(
        section: revision.section,
        html: revision.content_after,
        editor_name: nil,
        edit_reason: I18n.t("revisions.rollback_reason", version: revision.version),
        source: "rollback"
      )
      redirect_to admin_lesson_revisions_path(@lesson), notice: I18n.t("flash.lesson_rolled_back")
    end

    private

    def set_lesson
      @lesson = Lesson.find_by!(slug: params[:lesson_slug])
    end
  end
end
