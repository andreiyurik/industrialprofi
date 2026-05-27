module Admin
  class LessonsController < BaseController
    def index
      @paths = Path.ordered.includes(lessons: :path)
    end

    def edit
      @lesson = Lesson.find_by!(slug: params[:slug])
    end

    def update
      @lesson = Lesson.find_by!(slug: params[:slug])
      if @lesson.update(lesson_params)
        redirect_to edit_admin_lesson_path(@lesson), notice: I18n.t("flash.lesson_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def lesson_params
      params.require(:lesson).permit(:title, :description, :body, :task)
    end
  end
end
