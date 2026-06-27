class LessonRevision < ApplicationRecord
  SECTIONS = %w[body task description].freeze
  SOURCES  = %w[suggestion admin rollback].freeze

  # touch: every content change records a revision, so touching the lesson here
  # bumps its updated_at — busting the rendered-HTML cache (ApplicationHelper#
  # lesson_content) and the anonymous conditional-GET key (LessonsController).
  # Editing rich text alone wouldn't bump it otherwise (it's a separate record).
  belongs_to :lesson, counter_cache: true, touch: true
  belongs_to :lesson_suggestion, optional: true

  validates :version, presence: true
  validates :section, inclusion: { in: SECTIONS }
  validates :source, inclusion: { in: SOURCES }

  scope :ordered, -> { order(version: :desc) }

  # Revisions are an immutable audit log: they can be created (and destroyed
  # with their lesson), but never edited after the fact.
  def readonly? = persisted?

  def diff
    RevisionDiff.new(content_before, content_after)
  end
end
