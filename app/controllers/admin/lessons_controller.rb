module Admin
  class LessonsController < BaseController
    before_action :set_lesson, only: %i[edit update]

    def index
      @paths = Path.ordered.includes(:lessons)
    end

    def edit
      populate_rich_text_from_markdown
    end

    def update
      @lesson.admin_update_with_revisions!(lesson_params, edit_reason: params.dig(:lesson, :edit_reason))
      redirect_to edit_admin_lesson_path(@lesson), notice: I18n.t("flash.lesson_updated")
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    private

    def set_lesson
      @lesson = Lesson.find_by!(slug: params[:slug])
    end

    def populate_rich_text_from_markdown
      %i[description body task].each do |field|
        rich_field = :"rich_#{field}"
        if @lesson.send(rich_field).blank? && @lesson.send(field).present?
          html = helpers.markdown(@lesson.send(field))
          @lesson.send(rich_field).body = html
        end
      end
    end

    def lesson_params
      params.require(:lesson).permit(:title, :description, :body, :task, :kind, :rich_description, :rich_body, :rich_task)
    end
  end
end
