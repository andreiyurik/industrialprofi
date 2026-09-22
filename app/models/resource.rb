class Resource < ApplicationRecord
  belongs_to :lesson
  # contributor_name is denormalized credit that survives the account.
  belongs_to :contributor, class_name: "User", optional: true, foreign_key: "user_id"

  # `document` is a legacy kind: old rows sniff norm/book by title; new rows pick directly.
  KINDS = %w[norm book doc course video article software tool].freeze
  LANGUAGES = %w[en].freeze

  before_validation { self.country_code = country_code.presence }
  before_validation { self.language = language.presence }

  validates :title, presence: true
  validates :note, length: { maximum: 200 }
  validates :url, format: { with: URL_FORMAT }, allow_blank: true
  validates :kind, inclusion: { in: KINDS + %w[document] }
  validates :language, inclusion: { in: LANGUAGES }, allow_nil: true
  # No digest — edit-safety rides on the parent lesson's freeze, not this column.
  validates :origin, inclusion: { in: Importable::ORIGINS }

  scope :ordered, -> { order(:position) }
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :for_country, ->(code) { where(country_code: [ nil, code ]) }
  scope :published, -> {
    joins(lesson: [ :course, :path ])
      .where(courses: { status: "published" }, paths: { status: "published" })
  }
end
