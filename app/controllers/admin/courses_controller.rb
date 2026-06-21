module Admin
  class CoursesController < BaseController
    before_action :set_course, only: %i[edit update]

    def index
      @paths = Path.ordered.includes(:courses)
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to edit_admin_course_path(@course), notice: I18n.t("flash.course_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_course
      @course = Course.find_by!(slug: params[:slug])
    end

    def course_params
      params.require(:course).permit(:title, :slug, :description, :status, :position)
    end
  end
end
