# pending → approved/rejected; the fallback email fires only for a decision unseen in-app.
module SuggestionModeration
  extend ActiveSupport::Concern

  STATUSES = %w[pending approved rejected].freeze
  # A day for the author to see the decision on their dashboard, making the email unnecessary.
  OUTCOME_EMAIL_AFTER = 24.hours

  included do
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

  # Drives the fresh notify-dot; seen_at is captured before the visit marks everything seen.
  def freshly_decided?(seen_at)
    decided? && reviewed_at.present? && (seen_at.nil? || reviewed_at > seen_at)
  end

  def needs_outcome_email?
    user.present? && !user.suspended? && user.suggestion_emails? && !seen_by_author?
  end

  def seen_by_author?
    user&.suggestions_seen_at.present? && reviewed_at.present? &&
      user.suggestions_seen_at >= reviewed_at
  end
end
