module StylesheetsHelper
  # Our own stylesheets ship as ONE built file (see application.scss); these are
  # the ones gems put on the load path — lexxy and trix, for the rich-text
  # editor. They can't join the Sass build because they live outside the app, so
  # they stay separate <link>s. Derived, not listed, so a gem upgrade that
  # renames a file can't silently drop it.
  def vendor_stylesheets
    all_stylesheets_paths - app_stylesheets_paths
  end
end
