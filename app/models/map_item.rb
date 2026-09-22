# Either an overlay on a catalog lesson (`lesson_id` + `excluded`/`note`), or
# the author's own link, hung under a lesson (`after_lesson_id`) or loose at the end.
class MapItem < ApplicationRecord
  belongs_to :map, inverse_of: :items
  belongs_to :lesson, optional: true
  belongs_to :after_lesson, class_name: "Lesson", optional: true

  normalizes :title, :url, :note, with: ->(text) { text.strip.presence }

  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :title, presence: true, length: { maximum: 160 }, unless: :lesson?
  validates :url, presence: true, format: { with: URL_FORMAT }, length: { maximum: 500 }, unless: :lesson?
  validates :note, length: { maximum: 200 }

  scope :lessons, -> { where.not(lesson_id: nil) }
  scope :links, -> { where(lesson_id: nil) }

  def lesson? = lesson_id.present?
  def link? = !lesson?
  def comment? = lesson? && !excluded? && note.present?

  # The bare domain, shown next to an off-site link before the reader clicks.
  def host
    URI.parse(url.to_s).host&.delete_prefix("www.")
  rescue URI::InvalidURIError
    nil
  end
end
