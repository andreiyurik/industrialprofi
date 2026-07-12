# A message straight to the founder — the in-app feedback line. Async on
# purpose: no chat, no presence, no expectations of an instant reply. The
# founder reads them in /admin/feedbacks and answers by email. Usually from a
# signed-in learner (the address is known); business inquiries (/business) may
# arrive without a user — their contact is folded into the body.
class Feedback < ApplicationRecord
  # A tagged coauthor application (from /contribute) is an ordinary Feedback
  # carrying this stable marker in page_url — no separate model until real
  # application volume warrants tracking status (see CoauthorApplicationsController).
  # Both the writer and the scope use this constant so they can't drift apart.
  COAUTHOR_APPLICATION_PATH = "/coauthor_application/new".freeze

  belongs_to :user, optional: true

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :coauthor_applications, -> { where(page_url: COAUTHOR_APPLICATION_PATH) }

  def coauthor_application?
    page_url == COAUTHOR_APPLICATION_PATH
  end

  # The profession the applicant named, parsed from the structured body so the
  # approve form can prefill it. Uses the same i18n label the body was composed
  # with; a miss just leaves the field blank for the admin to type.
  def suggested_profession
    return unless coauthor_application?

    label = I18n.t("coauthor_applications.message.profession")
    line = body.to_s.lines.find { |row| row.strip.start_with?("#{label}:") }
    line&.split(":", 2)&.last&.strip.presence
  end
end
