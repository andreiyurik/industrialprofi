class Lesson < ApplicationRecord
  include IndexNowNotifiable
  include Illustratable
  include Importable
  include ImportedChildren
  include Revisable
  include Sluggable

  IMPORTABLE_FIELDS = %w[title description body task kind difficulty stage position].freeze

  belongs_to :course, counter_cache: true
  belongs_to :path, counter_cache: true
  has_many :resources, -> { order(:position) }, dependent: :destroy
  has_many :glossary_terms, -> { alphabetical }, dependent: :delete_all
  # Must precede lesson_suggestions — a revision FKs a suggestion.
  has_many :lesson_revisions, dependent: :delete_all
  has_many :lesson_suggestions, dependent: :destroy
  has_many :resource_suggestions, dependent: :destroy
  has_many :lesson_completions, dependent: :delete_all
  has_many :lesson_bookmarks, dependent: :delete_all
  has_many :journal_entries, dependent: :nullify
  has_many :map_items, dependent: :delete_all
  has_many :map_links, class_name: "MapItem", foreign_key: :after_lesson_id, dependent: :nullify

  accepts_nested_attributes_for :resources, allow_destroy: true,
    reject_if: ->(attrs) { attrs["title"].blank? && attrs["url"].blank? }
  accepts_nested_attributes_for :glossary_terms, allow_destroy: true,
    reject_if: ->(attrs) { attrs["abbr"].blank? && attrs["full"].blank? }

  has_rich_text :rich_body
  has_rich_text :rich_description
  has_rich_text :rich_task

  has_many_attached :illustrations

  before_validation { self.path = course.path if course }

  after_save_commit :index_for_search
  after_destroy_commit :deindex_for_search

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :kind, inclusion: { in: %w[lesson practice] }
  validates :difficulty, inclusion: { in: DIFFICULTIES = %w[beginner intermediate advanced] },
                         if: :practice?
  validates :difficulty, absence: true, unless: :practice?

  scope :ordered, -> { order(:position) }
  scope :practice, -> { where(kind: "practice") }
  scope :top_bookmarked, ->(count) {
    joins(:lesson_bookmarks)
      .select("lessons.*, COUNT(lesson_bookmarks.id) AS bookmarks_count")
      .group("lessons.id")
      .order(Arel.sql("COUNT(lesson_bookmarks.id) DESC"))
      .limit(count)
  }

  scope :title_search, ->(filter) {
    query = filter.to_s.strip
    query.present? ? where("title LIKE ?", "%#{sanitize_sql_like(query)}%").order(:title) : none
  }

  def practice? = kind == "practice"

  def to_param
    slug
  end

  def has_description? = rich_description.present? || description.present?
  def has_body?        = rich_body.present? || body.present?
  def has_task?        = rich_task.present? || task.present?
  def has_resources?   = resources.any?

  SELF_CHECK_PATTERN = /\[!ПРОВЕРЬ\]|самопроверк|проверь себя/i

  def missing_self_check?
    has_body? && !body_text.match?(SELF_CHECK_PATTERN)
  end

  # Scans raw sources, not to_plain_text, which would drop the hrefs.
  INTERNAL_LINK_PATTERN = %r{/lessons/([a-z0-9\-]+)}

  def linked_lesson_slugs
    [ body.to_s, rich_body&.body.to_s ].join(" ").scan(INTERNAL_LINK_PATTERN).flatten.uniq - [ slug ]
  end

  def prev_in_path
    path.lessons.where("position < ?", position).ordered.last
  end

  def next_in_path
    path.lessons.where("position > ?", position).ordered.first
  end

  def to_markdown
    sections = []
    sections << "# #{title}"
    sections << description if description.present?
    sections << body if body.present?
    if task.present?
      sections << "## Задание"
      sections << task
    end
    sections.join("\n\n")
  end

  private
    def index_for_search = LessonSearch.index(self)
    def deindex_for_search = LessonSearch.remove(id)

    def body_text
      [ body, rich_body&.to_plain_text ].compact.join(" ")
    end

    def indexnow_url
      return unless course&.status == "published" && path&.status == "published"

      "#{indexnow_site_url}/lessons/#{slug}"
    end

    def indexnow_should_ping?
      previously_new_record? ||
        saved_change_to_title? || saved_change_to_slug? ||
        saved_change_to_body? || saved_change_to_description? || saved_change_to_task?
    end
end
