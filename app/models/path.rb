class Path < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  has_many :lessons, -> { order(:position) }, dependent: :destroy

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
end
