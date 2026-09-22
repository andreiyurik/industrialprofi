# An overlay on the official profession — only the difference from it is stored.
class Map < ApplicationRecord
  MAX_ITEMS = 200

  belongs_to :user
  belongs_to :path, optional: true
  has_many :items, -> { order(:position) }, class_name: "MapItem", dependent: :destroy, inverse_of: :map
  has_many :follows, class_name: "MapFollow", dependent: :destroy

  accepts_nested_attributes_for :items, allow_destroy: true,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["title"].blank? && attrs["url"].blank? }

  normalizes :title, :description, with: ->(text) { text.strip.presence }

  validates :user_id, uniqueness: true
  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 500 }
  validate :items_within_limit

  scope :readable, -> { includes(:items, path: { courses: :lessons }) }

  def to_param = user.handle

  # Walks associations in memory, so cost with `readable` is flat per map shown.
  def lessons_by_course
    return {} unless path

    dropped = excluded_lesson_ids
    path.courses.select(&:published?).filter_map { |course|
      lessons = course.lessons.reject { |lesson| dropped.include?(lesson.id) }
      [ course, lessons ] if lessons.any?
    }.to_h
  end

  def lessons = lessons_by_course.values.flatten

  def excluded_lesson_ids = items.filter_map { |item| item.lesson_id if item.excluded? }.to_set

  Extra = Struct.new(:note, :links)

  def extras_by_lesson
    notes = comments
    links = items.select(&:link?).group_by(&:after_lesson_id)
    (notes.keys | links.keys).to_h { |id| [ id, Extra.new(notes[id], links.fetch(id, [])) ] }
  end

  def comments = items.filter_map { |item| [ item.lesson_id, item.note ] if item.comment? }.to_h

  def completed_count(completed_ids)
    lessons.count { |lesson| completed_ids.include?(lesson.id) }
  end

  # Links filed under a dropped lesson are deleted along with it.
  def choose_lessons!(kept_ids, notes: {})
    kept = kept_ids.map(&:to_i).to_set
    keeping, dropped = catalog_lesson_ids.partition { |id| kept.include?(id) }
    wanted = comments.merge(notes.transform_values(&:presence))

    transaction do
      items.lessons.delete_all
      items.links.where(after_lesson_id: dropped).delete_all
      dropped.each { |id| items.create!(lesson_id: id, excluded: true) }
      keeping.each { |id| items.create!(lesson_id: id, note: wanted[id]) if wanted[id] }
      items.reset
    end
  end

  private
    def catalog_lesson_ids
      path ? path.lessons.joins(:course).merge(Course.published).pluck(:id) : []
    end

    def items_within_limit
      errors.add(:items, :too_long, count: MAX_ITEMS) if items.reject(&:marked_for_destruction?).size > MAX_ITEMS
    end
end
