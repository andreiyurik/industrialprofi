module Admin
  module Paths
    # A drag that reorders lessons (or moves one to another course) in the
    # builder. The whole work lives in Path::Curriculum.
    class LessonMovesController < Admin::BaseController
      def create
        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.reorder_lessons!(move_params)
        head :no_content
      end

      private
        def move_params
          params.permit(lessons: %i[id course_id stage]).fetch(:lessons, [])
        end
    end
  end
end
