module Admin
  module Paths
    # Inline rename of a section (stage) heading from the builder tree. The work
    # — updating the shared label across the course's lessons — lives in
    # Path::Curriculum#rename_stage!.
    class StageRenamesController < Admin::BaseController
      def update
        return head :unprocessable_entity if params[:value].blank?

        path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        path.rename_stage!(course_id: params[:course_id], from: params[:from], to: params[:value].strip)
        head :no_content
      end
    end
  end
end
