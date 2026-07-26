# The moderation lifecycle shared by the two kinds of reader contribution — a
# proposed text edit (LessonSuggestion) and a proposed source (ResourceSuggestion):
# pending → approved/rejected, plus the "close the loop" machinery. Both ride the
# same seen-timestamp (User#suggestions_seen_at): the dashboard shows the outcome,
# and the fallback email fires only for a decision the author didn't see in-app.
module SuggestionModeration
  extend ActiveSupport::Concern

  STATUSES = %w[pending approved rejected].freeze
  # Grace period before the outcome email: a day for the author to see the
  # decision on their dashboard, which makes the email unnecessary.
  OUTCOME_EMAIL_AFTER = 24.hours

  included do
    # Optional: a contribution outlives the account; author_name stays denormalized.
    belongs_to :user, optional: true

    validates :author_name, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :pending,  -> { where(status: "pending") }
    scope :approved, -> { where(status: "approved") }
    scope :rejected, -> { where(status: "rejected") }
    scope :decided,  -> { where(status: %w[approved rejected]) }
  end

  def pending?  = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"
  def decided?  = approved? || rejected?

  # A decision made (or re-made) since the author last saw their dashboard —
  # drives the fresh notify-dot. seen_at is captured before the visit marks
  # everything seen.
  def freshly_decided?(seen_at)
    decided? && reviewed_at.present? && (seen_at.nil? || reviewed_at > seen_at)
  end

  # Email the author only when the loop isn't already closed: they still have an
  # account, can receive mail, opted in, and haven't seen the decision in-app.
  def needs_outcome_email?
    user.present? && !user.suspended? && user.suggestion_emails? && !seen_by_author?
  end

  # The author visited their dashboard (which marks contributions seen) after
  # this decision was made — Fizzy's "unread at delivery time" check.
  def seen_by_author?
    user&.suggestions_seen_at.present? && reviewed_at.present? &&
      user.suggestions_seen_at >= reviewed_at
  end
end
