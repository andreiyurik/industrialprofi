# Immutable edit-history behind a lesson's content: section HTML, versioned revisions, contributor credit.
# lesson_revisions stays on Lesson — delete_all must precede lesson_suggestions in the destroy cascade (see lesson.rb).
module Revisable
  extend ActiveSupport::Concern

  def revised? = lesson_revisions_count.positive?

  # Frozen once any revision exists: admin edits/suggestions land in rich text, invisible to the digest.
  def frozen_for_import?
    super || lesson_revisions.exists?
  end

  # Mirrors how the view renders a section — rich text if present, else the markdown fallback.
  def section_html(section)
    rich = public_send(:"rich_#{section}")
    return rich.body.to_html if rich.present?

    text = public_send(section)
    text.present? ? Kramdown::Document.new(text, input: "GFM").to_html : ""
  end

  # Records an immutable revision (version n+1) in one transaction. Used by suggestion approval and rollbacks.
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

  # One revision per section whose visible text changed, in one transaction.
  # origin becomes "human" — the YAML/AI importer leaves this lesson (and resources) alone forever.
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
