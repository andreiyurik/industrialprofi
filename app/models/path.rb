class Path < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Sluggable

  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  # Fields the YAML/AI importer manages (and digests for edit-safety). The slug
  # is the stable key, not content.
  IMPORTABLE_FIELDS = %w[title description position status].freeze

  has_many :courses, -> { order(:position) }, dependent: :destroy
  # NO dependent: :destroy here on purpose — Course owns the lesson destroy chain
  # (path → courses → lessons). Adding it back would destroy each lesson twice.
  # This association stays for total counts / catalog-wide lesson queries.
  has_many :lessons, -> { order(:position) }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :status, inclusion: { in: %w[draft pending_review published coming_soon] }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :locale, presence: true, format: { with: /\A[a-z]{2}\z/ }

  scope :published, -> { where(status: "published") }
  scope :listable, -> { where(status: %w[published coming_soon]) }
  scope :official, -> { where(author_id: nil) }
  scope :community, -> { where.not(author_id: nil) }
  scope :ordered, -> { order(:position) }
  # Each language market gets its own paths (TOP model, not synced translations) —
  # the catalog only ever lists the current locale's maps.
  scope :localized, ->(locale = I18n.locale) { where(locale: locale) }

  def coming_soon?
    status == "coming_soon"
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
