module RevisionsHelper
  # Tags/attrs a lesson section can legitimately use (prose + callouts + tables).
  # A reader's proposed_html may come from raw markdown (kramdown passes inline
  # HTML through), so the side-by-side view sanitises before rendering it.
  PROSE_TAGS = %w[p br hr h2 h3 h4 strong em b i u s del ins ul ol li blockquote
                  pre code a img figure figcaption div span table thead tbody tr th td].freeze
  PROSE_ATTRS = %w[href src alt title class colspan rowspan].freeze

  def inline_diff(before_html, after_html)
    RevisionDiff.new(before_html, after_html).to_html
  end

  def safe_prose(html)
    sanitize(html, tags: PROSE_TAGS, attributes: PROSE_ATTRS)
  end

  def revision_editor(revision)
    revision.editor_name.presence || t("revisions.by_admin")
  end
end
