module StylesheetsHelper
  # Gem-provided stylesheets (lexxy/trix) live outside the Sass build, so they stay separate
  # <link>s, and every <link> blocks first paint. REDUNDANT_STYLESHEETS are already covered
  # elsewhere: lexxy.css just @imports what we link; trix.css styles an editor we don't render.
  EDITOR_STYLESHEETS = %w[ lexxy-editor.css ]
  REDUNDANT_STYLESHEETS = %w[ lexxy.css trix.css ]

  # Derived by exclusion, not listed, so a gem upgrade that adds or renames a file degrades
  # to "shipped to everyone", never to "silently gone".
  # content_for :rich_text_editor is readable here because a view renders before its layout.
  def vendor_stylesheets
    gem_stylesheets - REDUNDANT_STYLESHEETS -
      (content_for?(:rich_text_editor) ? [] : EDITOR_STYLESHEETS)
  end

  private
    def gem_stylesheets
      all_stylesheets_paths - app_stylesheets_paths
    end
end
