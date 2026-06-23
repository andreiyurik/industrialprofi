module Admin
  class BaseController < ApplicationController
    # The whole admin namespace is content work (lessons, paths, suggestions),
    # open to editors. User/role management re-tightens with ensure_can_administer.
    before_action :ensure_can_edit_content

    # The moderation-queue size shown in the persistent admin nav (and the
    # dashboard callout) — one cheap COUNT per admin page render.
    helper_method :pending_suggestions_count, :unread_feedbacks_count, :can_publish?

    LIVE_STATUSES = %w[published coming_soon].freeze
    EDITOR_STATUSES = %w[draft pending_review].freeze

    private
      # The trust ladder for publishing: only administrators make content live.
      # Editors work in draft / pending_review and can request review, but can't
      # publish — and can't change a status that's already live.
      def can_publish? = Current.user.can_administer?

      def sanitized_status(requested, current:)
        return current if requested.blank?
        return requested if can_publish?
        return current if LIVE_STATUSES.include?(current)

        EDITOR_STATUSES.include?(requested) ? requested : current
      end

      def pending_suggestions_count
        @pending_suggestions_count ||= LessonSuggestion.pending.count
      end

      def unread_feedbacks_count
        @unread_feedbacks_count ||= Feedback.unread.count
      end

      def ensure_can_edit_content
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_edit_content?
      end

      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
