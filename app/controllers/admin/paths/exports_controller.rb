module Admin
  module Paths
    # Download a profession as a content pack — a .zip of the exporter's tree,
    # the same archive /admin/imports accepts. Closes the round-trip without
    # console access: an editor takes their map offline (backup, AI factory,
    # another install), then brings it back through the dry-run preview.
    class ExportsController < Admin::BaseController
      def show
        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        send_data CurriculumExporter.zip(path),
          filename: "#{path.slug}.zip", type: "application/zip"
      end
    end
  end
end
