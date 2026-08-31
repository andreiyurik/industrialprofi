module Admin
  # The image control room, one profession at a time. The landing lists every
  # profession with its illustration health (briefs waiting / images live /
  # broken references) — numbers only, no thumbnails, so the page stays light
  # however large the catalog grows. Opening a profession shows its brief
  # queue, the gallery of images readers actually see, and any broken
  # references. Editor-gated (BaseController); an editor trusted with exactly
  # one profession lands straight in it.
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

    # The fill screen for one placeholder: the brief, one file field, one
    # button. Reached from the reader-page pending box (?src= / ?brief=) and
    # the brief queue above; with no match it degrades to a slot chooser.
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
