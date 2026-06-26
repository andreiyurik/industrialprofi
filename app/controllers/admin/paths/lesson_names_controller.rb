module Admin
  module Paths
    # Inline rename of a lesson title from the builder tree.
    class LessonNamesController < Admin::BaseController
      def update
        return head :unprocessable_entity if params[:value].blank?

        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.lessons.find_by!(slug: params[:id]).update!(title: params[:value].strip, origin: "human")
        head :no_content
      end
    end
  end
end
