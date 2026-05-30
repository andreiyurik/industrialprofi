class LessonSuggestion < ApplicationRecord
  belongs_to :lesson

  has_rich_text :rich_body

  validate :body_content_present
  validates :author_name, presence: true
  validates :section, inclusion: { in: %w[body task description] }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: "pending") }

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

  private

  def body_content_present
    errors.add(:rich_body, :blank) if rich_body.blank? && body_markdown.blank?
  end
end
