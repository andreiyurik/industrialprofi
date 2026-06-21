class Lesson < ApplicationRecord
  include IndexNowNotifiable

  belongs_to :course, counter_cache: true
  # path_id is a denormalized FK (= course.path) kept in sync below. Many hot
  # queries join lessons.path_id directly (User progress, Projects, Sitemaps),
  # and lessons never move between courses, so it can't drift. Keeping it avoids
  # rewriting every join through courses.
  belongs_to :path, counter_cache: true
  has_many :resources, -> { order(:position) }, dependent: :destroy
  has_many :lesson_suggestions, dependent: :destroy
  has_many :lesson_revisions, dependent: :destroy

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

  def prev_in_path
    path.lessons.where("position < ?", position).ordered.last
  end

  def next_in_path
    path.lessons.where("position > ?", position).ordered.first
  end

  def revised? = lesson_revisions_count.positive?

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

  # Apply an admin edit (title/kind + rich sections) and record one revision per
  # section whose visible text actually changed — all in one transaction.
  def admin_update_with_revisions!(attrs, edit_reason:)
    transaction do
      befores = LessonRevision::SECTIONS.index_with { |section| section_html(section) }
      assign_attributes(attrs)
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
