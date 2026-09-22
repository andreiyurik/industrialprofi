module Admin
  module Paths
    # Drag reorder for courses; the work (incl. renumbering lessons to keep the
    # global order) lives in Path::Curriculum.
    class CourseMovesController < Admin::BaseController
      def create
        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.reorder_courses!(params.permit(course_ids: []).fetch(:course_ids, []))
        head :no_content
      end
    end
  end
end
