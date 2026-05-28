module RevisionsHelper
  def inline_diff(before_html, after_html)
    RevisionDiff.new(before_html, after_html).to_html
  end

  def revision_editor(revision)
    revision.editor_name.presence || t("revisions.by_admin")
  end
end
