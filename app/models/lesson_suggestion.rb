class LessonSuggestion < ApplicationRecord
  belongs_to :lesson

  validates :body_markdown, presence: true
  validates :author_name, presence: true
  validates :section, inclusion: { in: %w[body task description] }
  validates :status, inclusion: { in: %w[pending approved rejected] }

  scope :pending, -> { where(status: "pending") }
end
