module StylesheetsHelper
  # Our own stylesheets ship as ONE built file (see application.scss); these are
  # the ones gems put on the load path — lexxy and trix, for the rich-text
  # editor. They can't join the Sass build because they live outside the app, so
  # they stay separate <link>s, and every <link> blocks the first paint. Which is
  # why a reader gets only the two that style RENDERED rich text:
  #
  #   lexxy-editor.css  the editor's own chrome; four pages host an editor
  #   lexxy.css         nothing but an @import of the two we already link
  #   trix.css          ActionText's legacy editor, which lexxy replaced — the app
  #                     renders no trix-editor, and lexxy-content.css carries the
  #                     .attachment rules that rendered content needs
  EDITOR_STYLESHEETS = %w[ lexxy-editor.css ]
  REDUNDANT_STYLESHEETS = %w[ lexxy.css trix.css ]

  # Still derived by exclusion rather than listed, so a gem upgrade that adds or
  # renames a file degrades to "shipped to everyone", never to "silently gone".
  #
  # A page that hosts an editor asks for the rest with
  # `content_for :rich_text_editor` — readable here because a view renders
  # before the layout that wraps it.
  def vendor_stylesheets
    gem_stylesheets - REDUNDANT_STYLESHEETS -
      (content_for?(:rich_text_editor) ? [] : EDITOR_STYLESHEETS)
  end

  private
    def gem_stylesheets
      all_stylesheets_paths - app_stylesheets_paths
    end
end
