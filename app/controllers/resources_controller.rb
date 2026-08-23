class ResourcesController < ApplicationController
  allow_unauthenticated_access

  # The public document library: every published profession with a preview of
  # its top documents. One profession's full library is its hub «Библиотека»
  # tab — the old ?path=<slug> page 301s there.
  def index
    if params[:path].present?
      path = Path.published.localized.find_by!(slug: params[:path])
      return redirect_to path_library_path(path), status: :moved_permanently
    end

    version = ResourceLibrary.version
    @groups = Path.published.localized.ordered
                  .map { |path| [ path, ResourceLibrary.for(path:, version:) ] }
                  .reject { |_path, entries| entries.empty? }
  end
end
