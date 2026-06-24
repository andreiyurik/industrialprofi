module Admin
  class BaseController < ApplicationController
    # The whole admin namespace is content work (lessons, paths, suggestions),
    # open to editors. User/role management re-tightens with ensure_can_administer.
    before_action :ensure_can_edit_content

    # The moderation-queue size shown in the persistent admin nav (and the
    # dashboard callout) — one cheap COUNT per admin page render.
    helper_method :pending_suggestions_count, :unread_feedbacks_count, :can_publish?,
                  :slug_locked?, :status_live?, :can_edit_path?

    LIVE_STATUSES = %w[published coming_soon].freeze
    EDITOR_STATUSES = %w[draft pending_review].freeze

    private
      # The trust ladder for publishing: only administrators make content live.
      # Editors work in draft / pending_review and can request review, but can't
      # publish — and can't change a status that's already live.
      def can_publish? = Current.user.can_administer?

      # A live record's slug is part of indexed/linked URLs: changing it would
      # 404 the old URL and lose its SEO with no redirect. So lock the slug once
      # published/coming_soon — drafts (not public) stay freely renamable.
      def slug_locked?(record)
        record&.persisted? && status_live?(record)
      end

      # A live (published/coming_soon) record — editors can't change its status.
      def status_live?(record) = LIVE_STATUSES.include?(record.status)

      def sanitized_status(requested, current:)
        return current if requested.blank?
        return requested if can_publish?
        return current if LIVE_STATUSES.include?(current)

        EDITOR_STATUSES.include?(requested) ? requested : current
      end

      # Direct edit access to one profession — admins everywhere, editors only
      # where granted. The single gate every content action runs through.
      def can_edit_path?(record)
        Current.user.can_edit_path?(record.is_a?(Path) ? record : record&.path)
      end

      # Block an editor from touching a profession they weren't granted; bounce
      # them back to their own workspace, not the admin-only dashboard.
      def authorize_path!(record)
        redirect_to admin_lessons_path, alert: t("auth.not_authorized") unless can_edit_path?(record)
      end

      # Suggestions the current user may moderate: all for admins, only their
      # granted professions for editors. Scopes both the nav count and the queue.
      def editable_suggestions
        return LessonSuggestion.all if Current.user.administrator?

        LessonSuggestion.joins(:lesson).where(lessons: { path_id: Current.user.editorships.select(:path_id) })
      end

      def pending_suggestions_count
        @pending_suggestions_count ||= editable_suggestions.pending.count
      end

      def unread_feedbacks_count
        @unread_feedbacks_count ||= Feedback.unread.count
      end

      # Append-only transparency log — our Special:Log. Records a privileged
      # action over people or moderation so it stays reviewable. The
      # human-readable bits are denormalized into `details` so the entry keeps
      # its meaning even if the actor or target is later deleted. Call inside
      # the same transaction as the action it records, so they commit together.
      def record_admin_action(action, target: nil, **details)
        AdminAction.create!(actor: Current.user, action: action, target: target, details: details)
      end

      def ensure_can_edit_content
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_edit_content?
      end

      def ensure_can_administer
        redirect_to root_path, alert: t("auth.not_authorized") unless Current.user.can_administer?
      end
  end
end
