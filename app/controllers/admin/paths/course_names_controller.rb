module Admin
  module Paths
    # Inline rename of a course title from the builder tree.
    class CourseNamesController < Admin::BaseController
      def update
        return head :unprocessable_entity if params[:value].blank?

        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.courses.find_by!(slug: params[:id]).update!(title: params[:value].strip)
        head :no_content
      end
    end
  end
end
