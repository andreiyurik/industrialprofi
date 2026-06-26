class Lesson < ApplicationRecord
  include IndexNowNotifiable
  include Importable
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

  before_validation { self.path = course.path if course }

  has_rich_text :rich_body
  has_rich_text :rich_description
  has_rich_text :rich_task

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

  def prev_in_path
    path.lessons.where("position < ?", position).ordered.last
  end

  def next_in_path
    path.lessons.where("position > ?", position).ordered.first
  end

  def revised? = lesson_revisions_count.positive?

  # A lesson is also frozen for the importer once it carries any revision: admin
  # edits and approved suggestions land in rich text (not the markdown columns
  # the digest covers), so the digest alone wouldn't notice them.
  def frozen_for_import?
    super || lesson_revisions.exists?
  end

  # Community members who improved this lesson, earliest-first. A revision's
  # editor_name carries the suggester's name (set on approval); the founder's
  # direct admin edits store nil, so they never appear here — the credit goes
  # to contributors we want to motivate, and untouched lessons render nothing.
  def contributor_names
    lesson_revisions.where.not(editor_name: [ nil, "" ])
                    .group(:editor_name)
                    .order(Arel.sql("MIN(created_at)"))
                    .pluck(:editor_name)
  end

  # The HTML a reader currently sees for a section — rich text if present,
  # otherwise the markdown fallback rendered the same way the view renders it.
  def section_html(section)
    rich = public_send(:"rich_#{section}")
    return rich.body.to_html if rich.present?

    text = public_send(section)
    text.present? ? Kramdown::Document.new(text, input: "GFM").to_html : ""
  end

  # Apply new HTML to one section and record an immutable revision (version n+1),
  # all in a single transaction. Used by suggestion approval and rollbacks.
  def revise!(section:, html:, editor_name:, edit_reason:, source:, suggestion: nil)
    transaction do
      before = section_html(section)
      public_send(:"rich_#{section}").body = html
      save!
      record_revision!(
        section: section, before: before, after: section_html(section),
        editor_name: editor_name, edit_reason: edit_reason, source: source, suggestion: suggestion
      )
    end
  end

  # Apply an admin edit (title/kind + rich sections + resources) and record one
  # revision per section whose visible text actually changed — all in one
  # transaction. A human edit takes ownership: origin becomes "human" so the
  # YAML/AI importer leaves this lesson (and its resources) alone forever.
  def admin_update_with_revisions!(attrs, edit_reason:)
    transaction do
      befores = LessonRevision::SECTIONS.index_with { |section| section_html(section) }
      assign_attributes(attrs)
      self.origin = "human"
      save!
      befores.each do |section, before|
        after = section_html(section)
        next if RevisionDiff.new(before, after).identical?

        record_revision!(
          section: section, before: before, after: after,
          editor_name: nil, edit_reason: edit_reason, source: "admin"
        )
      end
    end
  end

  def record_revision!(section:, before:, after:, editor_name:, edit_reason:, source:, suggestion: nil)
    lesson_revisions.create!(
      section: section, content_before: before, content_after: after,
      editor_name: editor_name, edit_reason: edit_reason.presence,
      source: source, lesson_suggestion: suggestion, version: next_version
    )
  end

  def next_version = (lesson_revisions.maximum(:version) || 0) + 1

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
    def body_text
      [ body, rich_body&.to_plain_text ].compact.join(" ")
    end

    # Public only when both its course and profession are published.
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
