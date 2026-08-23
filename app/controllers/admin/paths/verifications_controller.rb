module Admin
  module Paths
    # The curator's "move the needle": hand-setting (and clearing) the
    # «проверено экспертом» mark on a profession — the one maturity rung that
    # is never computed. Both directions land in the transparency log.
    class VerificationsController < Admin::BaseController
      before_action :set_path

      def create
        # The ladder is enforced by the model; the button is already hidden when
        # it would be refused, so this is the belt to that suspender.
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
