class LessonSuggestion < ApplicationRecord
  # Status lifecycle + close-the-loop machinery (shared with ResourceSuggestion).
  include SuggestionModeration

  belongs_to :lesson

  has_rich_text :rich_body

  validate :body_content_present
  validates :section, inclusion: { in: %w[body task description] }

  # HTML regardless of rich-text vs markdown-fallback submission.
  def proposed_html
    if rich_body.present?
      rich_body.body.to_html
    else
      Kramdown::Document.new(body_markdown.to_s, input: "GFM").to_html
    end
  end

  # True when the section moved on since this suggestion's base was captured.
  def stale?
    base_content.present? && !RevisionDiff.new(base_content, lesson.section_html(section)).identical?
  end

  # Snapshot for #stale? to compare against later.
  def capture_base_content
    self.base_content = lesson.section_html(section) if LessonRevision::SECTIONS.include?(section)
  end

  private
    def body_content_present
      errors.add(:rich_body, :blank) if rich_body.blank? && body_markdown.blank?
    end
end
