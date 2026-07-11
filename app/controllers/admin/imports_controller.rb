module Admin
  class ImportsController < BaseController
    # Paste a profession (YAML) or upload a pack (.zip of the exported tree) →
    # preview a dry-run plan → import as draft. A zip is converted to the same
    # YAML document up front (CurriculumPack), so both inputs share one
    # pipeline. Output is always draft + origin "ai", so a human verifies and
    # publishes it afterwards through the normal trust ladder (see CurriculumDocument).
    def new
      @document = nil
    end

    def create
      @yaml = params[:archive].present? ? unpack_archive : params[:yaml].to_s
      return render :new, status: :unprocessable_entity if @yaml.nil?

      @document = CurriculumDocument.parse(@yaml)
      return render :new, status: :unprocessable_entity unless @document.valid?

      params[:confirm].present? ? commit : preview
    end

    private

    def unpack_archive
      pack = CurriculumPack.parse(params[:archive])
      yaml = pack.to_yaml
      @pack_errors = pack.errors
      @pack_warnings = pack.warnings
      yaml
    end

    def preview
      @plan = @document.plan(author: Current.user)
      return render :new, status: :unprocessable_entity unless @document.valid?

      render :preview
    end

    def commit
      result = @document.import!(author: Current.user)
      return render :new, status: :unprocessable_entity unless @document.valid? && result

      # The importer owns the new draft profession (admins edit all regardless).
      Current.user.editorships.create(path: result.path) unless Current.user.administrator?

      redirect_to edit_admin_path_path(result.path),
        notice: t("flash.import_done", courses: result.counts[:courses], lessons: result.counts[:lessons])
    end

    helper_method :import_error_messages, :import_warning_messages
    def import_error_messages
      (@pack_errors.to_a + @document&.errors.to_a).map do |error|
        error.is_a?(Symbol) ? t("admin.imports.errors.#{error}") : error
      end
    end

    def import_warning_messages
      @pack_warnings.to_a.map { |warning| t("admin.imports.warnings.#{warning}") }
    end
  end
end
