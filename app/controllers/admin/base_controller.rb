module Admin
  class BaseController < ApplicationController
    before_action :ensure_can_administer

    private
      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
