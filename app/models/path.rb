class Path < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Sluggable
  include Curriculum
  include Landing
  include Maturity

  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  STATUSES = %w[draft pending_review published].freeze

  KINDS = %w[role skill].freeze

  IMPORTABLE_FIELDS = %w[title description position status kind landing].freeze

  # inverse_of: a scoped has_many skips auto-detection — course.icon would re-query per card.
  has_many :courses, -> { order(:position) }, dependent: :destroy, inverse_of: :path
  # NO dependent: :destroy — Course owns the lesson destroy chain; adding it back double-destroys.
  has_many :lessons, -> { order(:position) }
  has_many :practice_lessons, -> { practice.ordered }, class_name: "Lesson"
  has_many :editorships, dependent: :destroy
  has_many :editors, through: :editorships, source: :user
  has_many :curators, -> { active.order(:name) }, through: :editorships, source: :user
  belongs_to :author, class_name: "User", optional: true
  has_many :maps, dependent: :nullify

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :status, inclusion: { in: STATUSES }
  validates :icon, inclusion: { in: ->(_) { Icon.emblems } }, allow_blank: true
  validates :kind, inclusion: { in: KINDS }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :locale, presence: true, format: { with: /\A[a-z]{2}\z/ }

  scope :published, -> { where(status: "published") }
  scope :official, -> { where(author_id: nil) }
  scope :community, -> { where.not(author_id: nil) }
  scope :ordered, -> { order(:position) }
  scope :with_practice_lessons, -> { where(id: Lesson.practice.select(:path_id)) }
  scope :editable_by, ->(user) {
    user.administrator? ? all : where(id: user.editorships.select(:path_id))
  }
  scope :localized, ->(locale = I18n.locale) { where(locale: locale) }

  def self.published_course_counts
    Course.where(status: "published").group(:path_id).count
  end

  def to_param
    slug
  end

  # Kept as a separate reader — overriding `icon` would break allow_blank and form checkedness.
  def emblem
    icon.presence || Icon::DEFAULT_EMBLEM
  end

  def has_glossary? = GlossaryTerm.for_path(self).exists?

  def contributors = @contributors ||= Contributors.new(self)

  def hub_curators = curators.includes(photo_attachment: :blob)

  private
    def indexnow_url
      "#{indexnow_site_url}/paths/#{slug}" if status == "published"
    end

    def indexnow_should_ping?
      saved_change_to_status? || saved_change_to_title? ||
        saved_change_to_description? || saved_change_to_slug?
    end
end
