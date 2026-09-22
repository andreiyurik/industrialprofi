class Lesson < ApplicationRecord
  include IndexNowNotifiable
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

  PENDING_IMAGE_PATTERN = /!\[(?<brief>[^\]]*)\]\(\s*(?<src>(?:TODO|placeholder)[^)]*?)\s*\)/i

  IllustrationSlot = Data.define(:section, :brief, :src) do
    def display_brief = brief.presence || src.sub(/\A(?:TODO[-_]?|placeholder:?)\s*/i, "").presence
  end

  def illustration_slots
    %w[body task].reject { |section| public_send(:"rich_#{section}").present? }
                 .flat_map do |section|
      public_send(section).to_s.scan(PENDING_IMAGE_PATTERN).map do |brief, src|
        IllustrationSlot.new(section:, brief:, src:)
      end
    end
  end

  def pending_illustration_briefs = illustration_slots.map(&:brief)

  class PlaceholderMissing < StandardError; end

  # Matches by exact src, not position — a concurrent edit removal raises, not corrupts text.
  def fill_illustration!(src:, blob:, edit_reason: nil)
    slot = illustration_slots.find { |candidate| candidate.src == src }
    raise PlaceholderMissing, src.to_s unless slot

    transaction do
      illustrations.attach(blob)
      url = Rails.application.routes.url_helpers.rails_service_blob_proxy_path(blob.signed_id, blob.filename)
      before = section_html(slot.section)
      public_send(:"#{slot.section}=",
        public_send(slot.section).sub(/\]\(\s*#{Regexp.escape(slot.src)}\s*\)/, "](#{url})"))
      self.origin = "human"
      save!
      # Not admin_update_with_revisions! — its diff is blind to a src-only change.
      record_revision!(section: slot.section, before: before, after: section_html(slot.section),
        editor_name: nil, edit_reason: edit_reason, source: "admin")
    end
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
