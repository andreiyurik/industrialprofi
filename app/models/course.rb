class Course < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Sluggable

  STATUSES = %w[draft pending_review published coming_soon].freeze

  IMPORTABLE_FIELDS = %w[title description position status].freeze

  belongs_to :path, counter_cache: true, inverse_of: :courses
  has_many :lessons, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :status, inclusion: { in: STATUSES }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :icon, inclusion: { in: ->(_) { Icon.emblems } }, allow_blank: true

  scope :published, -> { where(status: "published") }
  scope :listable, -> { where(status: %w[published coming_soon]) }
  scope :ordered, -> { order(:position) }

  def published? = status == "published"

  def coming_soon?
    status == "coming_soon"
  end

  # Blank is valid, not a gap — nothing distinguishes МИГ from ТИГ, and repeating a
  # glyph across sibling chapters reads as a bug. See Path#emblem for why this isn't an override.
  def emblem
    icon.presence || path.emblem
  end

  def to_param
    slug
  end

  # Pass the caller's preloaded lessons — avoids a fresh query per course on the dashboard.
  Progress = Struct.new(:done_count, :next_lesson, :lessons_count, :practice_count, keyword_init: true)

  def progress_for(lessons, completed_ids)
    lessons_count = lessons.count { |lesson| lesson.kind == "lesson" }
    Progress.new(
      done_count: lessons.count { |lesson| completed_ids.include?(lesson.id) },
      next_lesson: lessons.detect { |lesson| !completed_ids.include?(lesson.id) },
      lessons_count: lessons_count,
      practice_count: lessons.size - lessons_count
    )
  end

  private
    def indexnow_url
      return unless status == "published" && path&.status == "published"

      "#{indexnow_site_url}/courses/#{slug}"
    end

    def indexnow_should_ping?
      saved_change_to_status? || saved_change_to_title? ||
        saved_change_to_description? || saved_change_to_slug?
    end
end
