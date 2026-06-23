module Admin
  class ImportsController < BaseController
    # Paste a profession (YAML) → preview a dry-run plan → import as draft.
    # Output is always draft + origin "ai", so a human verifies and publishes it
    # afterwards through the normal trust ladder (see CurriculumDocument).
    def new
      @document = nil
    end

    def create
      @yaml = params[:yaml].to_s
      @document = CurriculumDocument.parse(@yaml)
      return render :new, status: :unprocessable_entity unless @document.valid?

      params[:confirm].present? ? commit : preview
    end

    private

    def preview
      @plan = @document.plan(author: Current.user)
      return render :new, status: :unprocessable_entity unless @document.valid?

      render :preview
    end

    def commit
      result = @document.import!(author: Current.user)
      return render :new, status: :unprocessable_entity unless @document.valid? && result

      redirect_to edit_admin_path_path(result.path),
        notice: t("flash.import_done", courses: result.counts[:courses], lessons: result.counts[:lessons])
    end

    helper_method :import_error_messages
    def import_error_messages
      @document&.errors.to_a.map { |error| error.is_a?(Symbol) ? t("admin.imports.errors.#{error}") : error }
    end
  end
end
