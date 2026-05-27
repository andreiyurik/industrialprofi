class Path < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  has_many :lessons, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT }
  validates :status, inclusion: { in: %w[draft pending_review published] }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :published, -> { where(status: "published") }
  scope :official, -> { where(author_id: nil) }
  scope :community, -> { where.not(author_id: nil) }
  scope :ordered, -> { order(:position) }

  def to_param
    slug
  end
end
