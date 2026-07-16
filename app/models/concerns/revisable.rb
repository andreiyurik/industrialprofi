# The immutable edit-history behavior behind a lesson's content: producing the
# HTML for a section, applying a change as a versioned revision, and reporting
# who contributed. The lesson_revisions association itself stays on Lesson —
# its dependent: :delete_all must run before lesson_suggestions in the destroy
# cascade (see lesson.rb), which an include-order accident could silently break.
module Revisable
  extend ActiveSupport::Concern

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
end
