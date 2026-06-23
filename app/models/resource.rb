class Resource < ApplicationRecord
  belongs_to :lesson

  # "" from the editor's "all countries" option means universal — store nil so
  # the for_country scope (nil = everyone) matches.
  before_validation { self.country_code = country_code.presence }

  validates :title, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/[^\s]+\z/i }
  validates :kind, inclusion: { in: %w[document video article tool] }
  # Provenance only (no digest): a resource's edit-safety rides on its parent
  # lesson being pristine. Importer-made rows are "seed"; once a human edits them
  # (Phase 1 editor) they become "human" and the importer leaves them alone.
  validates :origin, inclusion: { in: %w[human seed ai] }

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
