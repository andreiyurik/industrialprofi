module Admin
  module Paths
    # Downloads a profession as the same .zip /admin/imports accepts — round-trips
    # a map offline (backup, AI factory, another install) without console access.
    class ExportsController < Admin::BaseController
      def show
        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        send_data CurriculumExporter.zip(path),
          filename: "#{path.slug}.zip", type: "application/zip"
      end
    end
  end
end
