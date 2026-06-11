module Admin
  class BaseController < ApplicationController
    # The whole admin namespace is content work (lessons, paths, suggestions),
    # open to editors. User/role management re-tightens with ensure_can_administer.
    before_action :ensure_can_edit_content

    # The moderation-queue size shown in the persistent admin nav (and the
    # dashboard callout) — one cheap COUNT per admin page render.
    helper_method :pending_suggestions_count

    private
      def pending_suggestions_count
        @pending_suggestions_count ||= LessonSuggestion.pending.count
      end

      def ensure_can_edit_content
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_edit_content?
      end

      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
