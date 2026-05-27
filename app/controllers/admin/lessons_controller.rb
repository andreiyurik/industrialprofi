module Admin
  class LessonsController < BaseController
    before_action :set_lesson, only: %i[edit update]

    def index
      @paths = Path.ordered.includes(:lessons)
    end

    def edit; end

    def update
      if @lesson.update(lesson_params)
        redirect_to edit_admin_lesson_path(@lesson), notice: I18n.t("flash.lesson_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_lesson
      @lesson = Lesson.find_by!(slug: params[:slug])
    end

    def lesson_params
      params.require(:lesson).permit(:title, :description, :body, :task, :kind)
    end
  end
end
