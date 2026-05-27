class LessonSuggestion < ApplicationRecord
  belongs_to :lesson

  has_rich_text :rich_body

  validate :body_content_present
  validates :author_name, presence: true
  validates :section, inclusion: { in: %w[body task description] }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: "pending") }

  private

  def body_content_present
    errors.add(:rich_body, :blank) if rich_body.blank? && body_markdown.blank?
  end
end
