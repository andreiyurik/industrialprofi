# Async by design: no chat, no presence, no expectation of an instant reply.
# The founder answers by email; a userless inquiry folds its contact into the body.
class Feedback < ApplicationRecord
  # An ordinary Feedback carrying this stable marker in page_url — no separate
  # model until volume warrants it. Shared constant so writer and scope can't drift.
  COAUTHOR_APPLICATION_PATH = "/coauthor_application/new".freeze

  belongs_to :user, optional: true

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  scope :coauthor_applications, -> { where(page_url: COAUTHOR_APPLICATION_PATH) }

  def coauthor_application?
    page_url == COAUTHOR_APPLICATION_PATH
  end

  # I18n header line makes the message recognizable among ordinary feedback.
  def self.compose_message(i18n_scope, fields:, values:)
    lines = [ I18n.t("#{i18n_scope}.message.header") ]
    fields.each do |field|
      lines << "#{I18n.t("#{i18n_scope}.message.#{field}")}: #{values[field]}"
    end
    lines.join("\n\n")
  end

  # Parses the same i18n label compose_message used, to prefill the approve form;
  # a miss just leaves the field blank.
  def suggested_profession
    return unless coauthor_application?

    label = I18n.t("coauthor_applications.message.profession")
    line = body.to_s.lines.find { |row| row.strip.start_with?("#{label}:") }
    line&.split(":", 2)&.last&.strip.presence
  end
end
