class Lesson < ApplicationRecord
  belongs_to :path, counter_cache: true
  has_many :resources, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position) }

  def to_param
    slug
  end
end
