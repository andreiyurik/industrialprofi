# A member's ONE personal map: the official profession as it stands, minus the
# lessons its author took off, plus their comments and their own links. An
# overlay, never a copy — only the difference is stored, so a lesson added to
# the profession later shows up here too and progress stays single. Public by
# link only (no listing, no ratings); the trust signal is the author, not a badge.
class Map < ApplicationRecord
  MAX_ITEMS = 200

  belongs_to :user
  belongs_to :path, optional: true
  has_many :items, -> { order(:position) }, class_name: "MapItem", dependent: :destroy, inverse_of: :map
  has_many :follows, class_name: "MapFollow", dependent: :destroy

  # The links editor: a NEW row with neither a title nor a URL is an abandoned
  # "add a link" and is ignored (same rule as Lesson#resources).
  accepts_nested_attributes_for :items, allow_destroy: true,
    reject_if: ->(attrs) { attrs["id"].blank? && attrs["title"].blank? && attrs["url"].blank? }

  normalizes :title, :description, with: ->(text) { text.strip.presence }

  validates :user_id, uniqueness: true
  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 500 }
  validate :items_within_limit

  # What it takes to read a map: the overlay rows and the profession they hang
  # on. A page showing several maps adds `:user` for the authors' bylines.
  scope :readable, -> { includes(:items, path: { courses: :lessons }) }

  def to_param = user.handle

  # Chapter => its lessons, both in the profession's own order, minus what the
  # author took off. Walks the associations in memory, so with `readable` the
  # cost is flat however many maps a page shows.
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

  # What the author added under each lesson: their comment and their links,
  # keyed by lesson id. Loose links (no lesson) sit under nil.
  Extra = Struct.new(:note, :links)

  def extras_by_lesson
    notes = comments
    links = items.select(&:link?).group_by(&:after_lesson_id)
    (notes.keys | links.keys).to_h { |id| [ id, Extra.new(notes[id], links.fetch(id, [])) ] }
  end

  # The author's one-line comments to the learner, by lesson id.
  def comments = items.filter_map { |item| [ item.lesson_id, item.note ] if item.comment? }.to_h

  # How many of the map's lessons this reader has ticked — the other half of
  # the progress bar is just `lessons.size`.
  def completed_count(completed_ids)
    lessons.count { |lesson| completed_ids.include?(lesson.id) }
  end

  # Set which catalog lessons the map keeps, with the author's comment per kept
  # lesson (`notes`: lesson id => text; a lesson the caller says nothing about
  # keeps the comment it has). Stores only the difference from the profession:
  # untick nothing and this writes no rows at all. Links under a dropped lesson
  # go with it; loose links are untouched.
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
    # The pool a map draws from: the profession's lessons in published chapters.
    def catalog_lesson_ids
      path ? path.lessons.joins(:course).merge(Course.published).pluck(:id) : []
    end

    def items_within_limit
      errors.add(:items, :too_long, count: MAX_ITEMS) if items.reject(&:marked_for_destruction?).size > MAX_ITEMS
    end
end
