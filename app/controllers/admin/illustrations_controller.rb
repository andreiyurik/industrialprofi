module Admin
  class IllustrationsController < BaseController
    before_action :set_lesson, only: %i[new create]

    def index
      if params[:path].present?
        @path = editable_paths.find_by!(slug: params[:path])
        @census = IllustrationCensus.new(@path)
      elsif (only = solo_editor_path)
        redirect_to admin_illustrations_path(path: only.slug)
      else
        @censuses = editable_paths.ordered.map { |path| [ path, IllustrationCensus.new(path) ] }
      end
    end

    def new
      @slots = @lesson.illustration_slots
      @slot = @slots.find { |slot| slot.src == params[:src] } ||
              (params[:brief].present? && @slots.find { |slot| slot.brief == params[:brief] })
      @slot = @slots.first if !@slot && @slots.one?
    end

    def create
      @slot = @lesson.illustration_slots.find { |slot| slot.src == illustration_params[:src] } or raise Lesson::PlaceholderMissing
      upload = illustration_params[:file]

      if (@rejection = LessonImageUpload.rejection(upload))
        render :new, status: :unprocessable_entity
      else
        @lesson.fill_illustration!(src: @slot.src, blob: LessonImageUpload.reader_ready_blob(upload),
          caption: illustration_params[:caption], edit_reason: t("admin.illustrations.fill_reason"))
        redirect_to admin_illustrations_path(path: @lesson.path.slug),
          notice: t("admin.illustrations.filled", lesson: @lesson.title)
      end
    rescue Lesson::PlaceholderMissing
      redirect_to new_admin_lesson_illustration_path(@lesson), alert: t("admin.illustrations.slot_missing")
    rescue LessonImageUpload::Unreadable
      @rejection = :not_image
      render :new, status: :unprocessable_entity
    end

    private

    def set_lesson
      @lesson = Lesson.find_by!(slug: params[:lesson_slug])
      authorize_path!(@lesson)
    end

    def illustration_params
      params.expect(illustration: [ :src, :file, :caption ])
    end

    def editable_paths = Path.editable_by(Current.user)

    def solo_editor_path
      return if Current.user.can_administer?
      paths = Current.user.editable_paths.to_a
      paths.first if paths.one?
    end
  end
end
