module Admin
  module Paths
    # A drag that reorders courses in the builder. The whole work lives in
    # Path::Curriculum (it also renumbers lessons to keep the global order).
    class CourseMovesController < Admin::BaseController
      def create
        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.reorder_courses!(params.permit(course_ids: []).fetch(:course_ids, []))
        head :no_content
      end
    end
  end
end
