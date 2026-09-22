module Admin
  module Paths
    # Inline stage-heading rename from the builder tree; updates the shared label
    # across the course's lessons via Path::Curriculum#rename_stage!.
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
