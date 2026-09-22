module Admin
  module Paths
    # Hand-sets/clears the «проверено экспертом» mark — the one maturity rung
    # that's never computed. Both directions land in the transparency log.
    class VerificationsController < Admin::BaseController
      before_action :set_path

      def create
        # Belt-and-suspenders: the model enforces the ladder; the button is already
        # hidden when it would be refused.
        unless @path.verifiable? && @path.verifiable_by?(Current.user)
          return redirect_to path_path(@path), alert: t("paths.maturity.verify_refused")
        end

        @path.transaction do
          @path.verify!(Current.user)
          record_admin_action("path_verified", target: @path, subject: @path.title)
        end
        redirect_to path_path(@path), notice: t("paths.maturity.verified_notice")
      end

      def destroy
        @path.transaction do
          @path.unverify!
          record_admin_action("path_unverified", target: @path, subject: @path.title)
        end
        redirect_to path_path(@path), notice: t("paths.maturity.unverified_notice")
      end

      private
        def set_path
          @path = Path.editable_by(Current.user).find_by!(slug: params[:path_slug])
        end
    end
  end
end
