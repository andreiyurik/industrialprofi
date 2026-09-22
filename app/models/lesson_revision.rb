class LessonRevision < ApplicationRecord
  SECTIONS = %w[body task description].freeze
  SOURCES  = %w[suggestion admin rollback].freeze

  # touch: bumps lesson.updated_at, busting the rendered-HTML cache and conditional-GET key.
  # Editing rich text alone wouldn't bump it otherwise (separate record).
  belongs_to :lesson, counter_cache: true, touch: true
  belongs_to :lesson_suggestion, optional: true

  validates :version, presence: true
  validates :section, inclusion: { in: SECTIONS }
  validates :source, inclusion: { in: SOURCES }

  scope :ordered, -> { order(version: :desc) }

  # Immutable audit log — created and destroyed with the lesson, never edited.
  def readonly? = persisted?

  def diff
    RevisionDiff.new(content_before, content_after)
  end
end
