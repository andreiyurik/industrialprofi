class Path < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Sluggable
  include Curriculum

  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  # draft/pending_review = not public; published = live; coming_soon = stub being
  # built ("В разработке"); planned = stub merely planned ("В планах").
  STATUSES = %w[draft pending_review published coming_soon planned].freeze

  # role = full career path from scratch ("Электрик", "Инженер АСУ ТП");
  # skill = specific tool/technology for working professionals ("Siemens TIA Portal", "SCADA").
  KINDS = %w[role skill].freeze

  # Fields the YAML/AI importer manages (and digests for edit-safety). The slug
  # is the stable key, not content.
  IMPORTABLE_FIELDS = %w[title description position status kind].freeze

  has_many :courses, -> { order(:position) }, dependent: :destroy
  # NO dependent: :destroy here on purpose — Course owns the lesson destroy chain
  # (path → courses → lessons). Adding it back would destroy each lesson twice.
  # This association stays for total counts / catalog-wide lesson queries.
  has_many :lessons, -> { order(:position) }
  # Practice lessons only — the journal links a practice task you did, not theory,
  # which keeps the "Связанный урок" picker short (see journal form).
  has_many :practice_lessons, -> { practice.ordered }, class_name: "Lesson"
  # Editors granted direct edit access to this profession (see Editorship).
  has_many :editorships, dependent: :destroy
  has_many :editors, through: :editorships, source: :user
  # Editors who opted in to be shown publicly as curators of this profession
  # (opt-in recognition; see User#public_curator).
  has_many :curators, -> { where(public_curator: true) }, through: :editorships, source: :user

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: KINDS }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :locale, presence: true, format: { with: /\A[a-z]{2}\z/ }

  scope :published, -> { where(status: "published") }
  # Catalog shows real maps + the "not yet" stubs (being built and merely planned).
  scope :listable, -> { where(status: %w[published coming_soon planned]) }
  scope :official, -> { where(author_id: nil) }
  scope :community, -> { where.not(author_id: nil) }
  scope :ordered, -> { order(:position) }
  scope :with_practice_lessons, -> { where(id: Lesson.practice.select(:path_id)) }
  # Professions a user may edit in the admin: admins see all, editors only the
  # ones granted to them. Backs the scoped admin index pages.
  scope :editable_by, ->(user) {
    user.administrator? ? all : where(id: user.editorships.select(:path_id))
  }
  # Each language market gets its own paths (TOP model, not synced translations) —
  # the catalog only ever lists the current locale's maps.
  scope :localized, ->(locale = I18n.locale) { where(locale: locale) }

  def coming_soon?
    status == "coming_soon"
  end

  def planned?
    status == "planned"
  end

  # A not-yet-available map shown in the catalog as a non-clickable stub —
  # either actively being built (coming_soon) or merely planned.
  def stub?
    coming_soon? || planned?
  end

  def to_param
    slug
  end

  private
    def indexnow_url
      "#{indexnow_site_url}/paths/#{slug}" if status == "published"
    end

    def indexnow_should_ping?
      saved_change_to_status? || saved_change_to_title? ||
        saved_change_to_description? || saved_change_to_slug?
    end
end
