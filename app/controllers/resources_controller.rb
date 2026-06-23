class ResourcesController < ApplicationController
  allow_unauthenticated_access

  # The public document library. Without a ?path it's a hub: every published
  # profession with a preview of its top documents. With ?path=<slug> it's that
  # profession's full library — a clean, crawlable, SEO-strong page.
  def index
    if params[:path].present?
      @path = Path.published.localized.find_by!(slug: params[:path])
      @entries = ResourceLibrary.for(path: @path)
    else
      @groups = Path.published.localized.ordered
                    .map { |path| [ path, ResourceLibrary.for(path:) ] }
                    .reject { |_path, entries| entries.empty? }
    end
  end
end
