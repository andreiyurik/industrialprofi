class Course < ApplicationRecord
  belongs_to :path, counter_cache: true
  has_many :lessons, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :status, inclusion: { in: %w[draft pending_review published coming_soon] }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(status: "published") }
  scope :listable, -> { where(status: %w[published coming_soon]) }
  scope :ordered, -> { order(:position) }

  def coming_soon?
    status == "coming_soon"
  end

  def to_param
    slug
  end
end
