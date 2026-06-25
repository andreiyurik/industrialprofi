class Resource < ApplicationRecord
  belongs_to :lesson

  # The two axes of a resource. KINDS = what it is (one per link). `document` is a
  # legacy kind kept valid for old rows — it splits to norm/book by title sniffing
  # at display (see ApplicationHelper#resource_badge_meta); new rows pick norm or
  # book explicitly. LANGUAGES = a source-language marker (nil = Russian),
  # orthogonal to kind, shown as a small secondary badge.
  KINDS = %w[norm book doc course video article software tool].freeze
  LANGUAGES = %w[en de].freeze

  # "" from the editor's "all countries"/"default language" options means
  # universal — store nil so the scopes (nil = everyone) match.
  before_validation { self.country_code = country_code.presence }
  before_validation { self.language = language.presence }

  validates :title, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }
  validates :kind, inclusion: { in: KINDS + %w[document] }
  validates :language, inclusion: { in: LANGUAGES }, allow_nil: true
  # Provenance only (no digest). Edit-safety rides primarily on the PARENT lesson's
  # freeze: the importer syncs resources only while the lesson is still pristine, so
  # an edited (frozen) lesson's links are never touched. The origin "human" guard is
  # the secondary seam for the day a single link is owned independently of its lesson
  # (a per-link editor); until then importer rows stay "seed"/"ai".
  validates :origin, inclusion: { in: Importable::ORIGINS }

  scope :ordered, -> { order(:position) }
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :for_country, ->(code) { where(country_code: [ nil, code ]) }
  # Resources visible on the public site: their lesson's course AND profession
  # are both published. Backs the /resources library (see ResourceLibrary).
  scope :published, -> {
    joins(lesson: [ :course, :path ])
      .where(courses: { status: "published" }, paths: { status: "published" })
  }
end
