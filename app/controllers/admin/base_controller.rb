module Admin
  class BaseController < ApplicationController
    # The whole admin namespace is content work (lessons, paths, suggestions),
    # open to editors. User/role management re-tightens with ensure_can_administer.
    before_action :ensure_can_edit_content

    private
      def ensure_can_edit_content
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_edit_content?
      end

      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
