module Admin
  class PlaceholdersController < BaseController
    before_action :set_lesson

    def destroy
      @lesson.remove_illustration!(src: params.expect(:src), edit_reason: t("admin.illustrations.remove_reason"))
      redirect_to admin_illustrations_path(path: @lesson.path.slug), notice: t("admin.illustrations.removed", lesson: @lesson.title)
    rescue Lesson::PlaceholderMissing
      redirect_to admin_illustrations_path(path: @lesson.path.slug), alert: t("admin.illustrations.slot_missing")
    end

    private
      def set_lesson
        @lesson = Lesson.find_by!(slug: params[:lesson_slug])
        authorize_path!(@lesson)
      end
  end
end
