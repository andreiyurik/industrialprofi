class Resource < ApplicationRecord
  belongs_to :lesson

  # "" from the editor's "all countries" option means universal — store nil so
  # the for_country scope (nil = everyone) matches.
  before_validation { self.country_code = country_code.presence }

  validates :title, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }
  validates :kind, inclusion: { in: %w[document video article tool] }
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
