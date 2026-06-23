module Admin
  class LessonsController < BaseController
    before_action :set_lesson, only: %i[edit update]
    before_action :set_editable_paths, only: %i[new create]

    def index
      @paths = Path.editable_by(Current.user).ordered.includes(:lessons)
    end

    # A lesson is born as a small stub (where it lives + title + kind); the rich
    # body/task and resources are filled in straight away on the edit page.
    def new
      @lesson = Lesson.new(course_id: params[:course_id], kind: "lesson")
    end

    def create
      @lesson = Lesson.new(new_lesson_params)
      unless can_edit_path?(@lesson.course)
        return redirect_to(admin_lessons_path, alert: t("auth.not_authorized"))
      end

      @lesson.position = next_lesson_position(@lesson.course)
      @lesson.difficulty ||= "beginner" if @lesson.practice?

      if @lesson.save
        redirect_to edit_admin_lesson_path(@lesson), notice: I18n.t("flash.lesson_created")
      else
        render :new, status: :unprocessable_entity
      end
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
      authorize_path!(@lesson)
    end

    def set_editable_paths
      @editable_paths = Path.editable_by(Current.user).ordered.includes(:courses)
    end

    # Position is global within the profession (continuous prev/next across
    # courses), so a new lesson appends to the end of its path.
    def next_lesson_position(course)
      return 1 unless course

      (course.path.lessons.maximum(:position) || 0) + 1
    end

    def new_lesson_params
      params.require(:lesson).permit(:course_id, :stage, :title, :slug, :kind)
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
      params.require(:lesson).permit(
        :title, :description, :body, :task, :kind,
        :rich_description, :rich_body, :rich_task,
        resources_attributes: %i[id title url kind required position _destroy]
      )
    end
  end
end
