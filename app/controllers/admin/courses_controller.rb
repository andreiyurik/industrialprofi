module Admin
  class CoursesController < BaseController
    before_action :set_course, only: %i[edit update destroy]
    before_action :set_editable_paths, only: %i[new create]

    def index
      @paths = Path.editable_by(Current.user).ordered.includes(:courses)
    end

    def new
      @course = Course.new(status: "draft", path_id: params[:path_id])
    end

    def create
      @course = Course.new(course_params)
      return redirect_to(admin_courses_path, alert: t("auth.not_authorized")) unless can_edit_path?(@course)

      @course.position = (@course.path&.courses&.maximum(:position) || 0) + 1 if @course.position.to_i.zero?
      @course.status = sanitized_status(params.dig(:course, :status), current: "draft")

      if @course.save
        redirect_to edit_admin_course_path(@course), notice: I18n.t("flash.course_created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    # Course owns the lesson destroy chain (path → courses → lessons), so this
    # also clears the course's lessons and their dependents.
    def destroy
      path = @course.path
      @course.destroy!
      redirect_to admin_path_path(path), notice: I18n.t("flash.course_deleted")
    end

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
      authorize_path!(@course)
    end

    def set_editable_paths
      @editable_paths = Path.editable_by(Current.user).ordered
    end

    # status is handled separately via sanitized_status (trust ladder). path_id
    # is create-only — courses don't move between professions, and permitting it
    # on update would let a scoped editor push a course into a profession they
    # don't own. slug is locked once the course is live (see slug_locked?).
    def course_params
      permitted = [ :title, :description, :position ]
      permitted << :path_id unless @course # only on create (set_course runs on update)
      permitted << :slug unless slug_locked?(@course)
      params.require(:course).permit(*permitted)
    end
  end
end
