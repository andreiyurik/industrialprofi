module Admin
  class IllustrationsController < BaseController
    before_action :set_lesson, only: %i[new create]

    def index
      if params[:path].present?
        @path = Path.find_by!(slug: params[:path])
        @census = IllustrationCensus.new(@path)
      elsif (only = solo_editor_path)
        redirect_to admin_illustrations_path(path: only.slug)
      else
        @censuses = Path.ordered.map { |path| [ path, IllustrationCensus.new(path) ] }
      end
    end

    def new
      @slots = @lesson.illustration_slots
      @slot = @slots.find { |slot| slot.src == params[:src] } ||
              (params[:brief].present? && @slots.find { |slot| slot.brief == params[:brief] })
      @slot = @slots.first if !@slot && @slots.one?
    end

    def create
      upload = illustration_params[:file]
      unless upload.respond_to?(:content_type) &&
             LessonImageUpload.permits?(content_type: upload.content_type, byte_size: upload.size)
        return redirect_to new_admin_lesson_illustration_path(@lesson, src: illustration_params[:src]),
          alert: t("admin.uploads.rejected", max: helpers.number_to_human_size(LessonImageUpload::MAX_BYTES))
      end

      blob = LessonImageUpload.reader_ready_blob(upload)
      @lesson.fill_illustration!(src: illustration_params[:src], blob: blob,
        edit_reason: t("admin.illustrations.fill_reason"))
      redirect_to lesson_path(@lesson), notice: t("admin.illustrations.filled")
    rescue Lesson::PlaceholderMissing
      redirect_to new_admin_lesson_illustration_path(@lesson), alert: t("admin.illustrations.slot_missing")
    end

    private

    def set_lesson
      @lesson = Lesson.find_by!(slug: params[:lesson_slug])
      authorize_path!(@lesson)
    end

    def illustration_params
      params.expect(illustration: [ :src, :file ])
    end

    def solo_editor_path
      return if Current.user.can_administer?
      paths = Current.user.editable_paths.to_a
      paths.first if paths.one?
    end
  end
end
