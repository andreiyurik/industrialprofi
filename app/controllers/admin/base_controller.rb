module Admin
  class BaseController < ApplicationController
    # Opens the whole admin namespace to editors; admin-only routes self-gate below.
    before_action :ensure_can_edit_content

    helper_method :pending_suggestions_count, :pending_resource_suggestions_count,
                  :unread_feedbacks_count, :can_publish?,
                  :slug_locked?, :status_live?, :can_edit_path?

    LIVE_STATUSES = %w[published coming_soon].freeze
    EDITOR_STATUSES = %w[draft pending_review].freeze

    private
      def can_publish? = Current.user.can_administer?

      # Live slugs are linked/indexed; changing one 404s the old URL.
      def slug_locked?(record)
        record&.persisted? && status_live?(record)
      end

      def status_live?(record) = LIVE_STATUSES.include?(record.status)

      def sanitized_status(requested, current:)
        return current if requested.blank?
        return requested if can_publish?
        return current if LIVE_STATUSES.include?(current)

        EDITOR_STATUSES.include?(requested) ? requested : current
      end

      def can_edit_path?(record)
        Current.user.can_edit_path?(record.is_a?(Path) ? record : record&.path)
      end

      def authorize_path!(record)
        redirect_to admin_lessons_path, alert: t("auth.not_authorized") unless can_edit_path?(record)
      end

      def editable_suggestions
        Current.user.reviewable_suggestions
      end

      def pending_suggestions_count
        @pending_suggestions_count ||= editable_suggestions.pending.count
      end

      def pending_resource_suggestions_count
        @pending_resource_suggestions_count ||= Current.user.reviewable_resource_suggestions.pending.count
      end

      def unread_feedbacks_count
        @unread_feedbacks_count ||= Feedback.unread.count
      end

      # details is denormalized so an entry keeps meaning after the actor or target is deleted.
      def record_admin_action(action, target: nil, **details)
        AdminAction.create!(actor: Current.user, action: action, target: target, details: details)
      end

      def notify_review_request(record)
        return unless record.status == "pending_review" && !Current.user.administrator?

        ReviewRequestsMailer.submitted(record, Current.user).deliver_later
      end

      def log_and_notify_status_change(record, action, **details)
        return unless record.saved_change_to_status?

        record_admin_action(action, target: record, from_status: record.status_before_last_save,
          to_status: record.status, **details)
        notify_review_request(record)
      end

      def ensure_can_edit_content
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_edit_content?
      end

      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
