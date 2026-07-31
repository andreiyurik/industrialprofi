class LessonSuggestion < ApplicationRecord
  # Status lifecycle + close-the-loop machinery (shared with ResourceSuggestion).
  include SuggestionModeration

  belongs_to :lesson

  has_rich_text :rich_body

  validate :body_content_present
  validates :section, inclusion: { in: %w[body task description] }

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

  private
    def body_content_present
      errors.add(:rich_body, :blank) if rich_body.blank? && body_markdown.blank?
    end
end
