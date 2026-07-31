class Lesson < ApplicationRecord
  include IndexNowNotifiable
  include Importable
  include Revisable
  include Sluggable

  # Digested for edit-safety. The raw markdown columns the importer writes; admin
  # edits live in rich text + leave a revision, which also freezes the lesson
  # (see frozen_for_import? below).
  IMPORTABLE_FIELDS = %w[title description body task kind difficulty stage position].freeze

  belongs_to :course, counter_cache: true
  # path_id is a denormalized FK (= course.path) kept in sync below. Many hot
  # queries join lessons.path_id directly (User progress, Projects, Sitemaps),
  # and lessons never move between courses, so it can't drift. Keeping it avoids
  # rewriting every join through courses.
  belongs_to :path, counter_cache: true
  has_many :resources, -> { order(:position) }, dependent: :destroy
  # Revisions are an immutable, readonly audit log, so they're cleared with
  # delete_all (destroy would raise ReadOnlyRecord). They must precede
  # lesson_suggestions in the cascade: a revision FKs a suggestion, so the
  # revisions have to go first.
  has_many :lesson_revisions, dependent: :delete_all
  has_many :lesson_suggestions, dependent: :destroy
  has_many :resource_suggestions, dependent: :destroy
  # Learner-side records vanish with the lesson; journal entries survive (their
  # lesson link is optional) and are just unlinked.
  has_many :lesson_completions, dependent: :delete_all
  has_many :lesson_bookmarks, dependent: :delete_all
  has_many :journal_entries, dependent: :nullify

  # The admin resource editor edits resources inline with the lesson. A row with
  # neither a title nor a URL (an empty "add a link" the editor left behind) is
  # ignored; rows flagged for removal are destroyed.
  accepts_nested_attributes_for :resources, allow_destroy: true,
    reject_if: ->(attrs) { attrs["title"].blank? && attrs["url"].blank? }

  has_rich_text :rich_body
  has_rich_text :rich_description
  has_rich_text :rich_task

  before_validation { self.path = course.path if course }

  after_save_commit :index_for_search
  after_destroy_commit :deindex_for_search

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: Path::SLUG_FORMAT }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :kind, inclusion: { in: %w[lesson practice] }
  # Difficulty grades the practice ladder (/projects filters); theory lessons
  # don't carry one.
  validates :difficulty, inclusion: { in: DIFFICULTIES = %w[beginner intermediate advanced] },
                         if: :practice?
  validates :difficulty, absence: true, unless: :practice?

  scope :ordered, -> { order(:position) }
  scope :practice, -> { where(kind: "practice") }
  # What readers actually want to keep — the save-for-later signal, ranked. An
  # inner join naturally drops anything with zero bookmarks.
  scope :top_bookmarked, ->(count) {
    joins(:lesson_bookmarks)
      .select("lessons.*, COUNT(lesson_bookmarks.id) AS bookmarks_count")
      .group("lessons.id")
      .order(Arel.sql("COUNT(lesson_bookmarks.id) DESC"))
      .limit(count)
  }

  # Title match for the editor's @-mention link picker (Admin::LessonLinksController).
  # Titles aren't sensitive, so it spans every profession — cross-links are the
  # point of the wiki fabric. Blank filter → nothing (the prompt shows its empty
  # state until the author types).
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

  # The convention a theory lesson ends on is a self-check block (`> [!ПРОВЕРЬ]`;
  # older "самопроверка" / "проверь себя" counts too). `content:audit` flags a
  # WRITTEN lesson that lacks one — scanning both the imported markdown and any
  # human rich-text edit.
  SELF_CHECK_PATTERN = /\[!ПРОВЕРЬ\]|самопроверк|проверь себя/i

  def missing_self_check?
    has_body? && !body_text.match?(SELF_CHECK_PATTERN)
  end

  # The wiki fabric `content:audit` watches: /lessons/<slug> links inside the
  # body. Scans the raw sources (markdown + rich-text HTML) — to_plain_text
  # would drop the hrefs.
  INTERNAL_LINK_PATTERN = %r{/lessons/([a-z0-9\-]+)}

  def linked_lesson_slugs
    [ body.to_s, rich_body&.body.to_s ].join(" ").scan(INTERNAL_LINK_PATTERN).flatten.uniq - [ slug ]
  end

  # Author image placeholders not yet replaced with a real picture: a markdown
  # image whose target is a "TODO-*.png" or "placeholder: …" stand-in. The brief
  # for the illustrator lives in the alt text — that's what /admin/illustrations
  # lists. Scanned from the raw markdown body/task, where seed placeholders live;
  # a lesson edited into rich_body no longer carries them.
  PENDING_IMAGE_PATTERN = /!\[(?<brief>[^\]]*)\]\(\s*(?:TODO|placeholder)[^)]*\)/i

  def pending_illustration_briefs
    [ body.to_s, task.to_s ].flat_map { |md| md.scan(PENDING_IMAGE_PATTERN) }.flatten
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
