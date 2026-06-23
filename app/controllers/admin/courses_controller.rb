module Admin
  class CoursesController < BaseController
    before_action :set_course, only: %i[edit update]

    def index
      @paths = Path.ordered.includes(:courses)
    end

    def new
      @course = Course.new(status: "draft", path_id: params[:path_id])
    end

    def create
      @course = Course.new(course_params)
      @course.position = (@course.path&.courses&.maximum(:position) || 0) + 1 if @course.position.to_i.zero?
      @course.status = sanitized_status(params.dig(:course, :status), current: "draft")

      if @course.save
        redirect_to edit_admin_course_path(@course), notice: I18n.t("flash.course_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @course.assign_attributes(course_params)
      @course.status = sanitized_status(params.dig(:course, :status), current: @course.status_was)

      if @course.save
        redirect_to edit_admin_course_path(@course), notice: I18n.t("flash.course_updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_course
      @course = Course.find_by!(slug: params[:slug])
    end

    # status is handled separately via sanitized_status (trust ladder). path_id
    # is only submitted when creating — courses don't move between professions.
    def course_params
      params.require(:course).permit(:path_id, :title, :slug, :description, :position)
    end
  end
end
