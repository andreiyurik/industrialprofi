module Admin
  # The image control room, one profession at a time. The landing lists every
  # profession with its illustration health (briefs waiting / images live /
  # broken references) — numbers only, no thumbnails, so the page stays light
  # however large the catalog grows. Opening a profession shows its brief
  # queue, the gallery of images readers actually see, and any broken
  # references. Editor-gated (BaseController); an editor trusted with exactly
  # one profession lands straight in it.
  class IllustrationsController < BaseController
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

    private

    def solo_editor_path
      return if Current.user.can_administer?
      paths = Current.user.editable_paths.to_a
      paths.first if paths.one?
    end
  end
end
