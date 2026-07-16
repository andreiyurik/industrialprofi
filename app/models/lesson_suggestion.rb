class LessonSuggestion < ApplicationRecord
  belongs_to :lesson
  # The account that made this suggestion — the identity a track record is
  # computed over. Optional: legacy/anonymous edits keep only author_name.
  belongs_to :user, optional: true

  has_rich_text :rich_body

  validate :body_content_present
  validates :author_name, presence: true
  validates :section, inclusion: { in: %w[body task description] }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending,  -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :decided,  -> { where(status: %w[approved rejected]) }

  def pending?  = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"

  # The proposed content as HTML, regardless of whether it was submitted via the
  # rich-text editor or the markdown fallback.
  def proposed_html
    if rich_body.present?
      rich_body.body.to_html
    else
      Kramdown::Document.new(body_markdown.to_s, input: "GFM").to_html
    end
  end

  # The section moved on since this edit was submitted, so the moderator is
  # reviewing against a newer base than the author saw.
  def stale?
    base_content.present? && !RevisionDiff.new(base_content, lesson.section_html(section)).identical?
  end

  # Snapshot the section as it stands right now, so a moderator can later be
  # warned if the lesson moved on in the meantime (see #stale?).
  def capture_base_content
    self.base_content = lesson.section_html(section) if LessonRevision::SECTIONS.include?(section)
  end

  # ── Outcome email (in-app first, email only as the unread fallback) ──
  # Grace period before the outcome email: a day for the author to see the
  # decision on their dashboard, which makes the email unnecessary.
  OUTCOME_EMAIL_AFTER = 24.hours

  # Email the author only when the loop isn't already closed: they still have
  # an account, can receive mail, opted in, and haven't seen the decision in
  # the app. SuggestionEmailsJob marks outcome_notified_at either way.
  def needs_outcome_email?
    user.present? && !user.suspended? && user.suggestion_emails? && !seen_by_author?
  end

  # The author visited their dashboard (which marks suggestions seen) after
  # this decision was made — Fizzy's "unread at delivery time" check.
  def seen_by_author?
    user.suggestions_seen_at.present? && reviewed_at.present? &&
      user.suggestions_seen_at >= reviewed_at
  end

  private

  def body_content_present
    errors.add(:rich_body, :blank) if rich_body.blank? && body_markdown.blank?
  end
end
