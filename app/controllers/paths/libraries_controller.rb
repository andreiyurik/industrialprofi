# The «Библиотека» tab of a profession hub: what a reader reaches for while
# working — the documents its lessons cite and the calculators built for its
# topics. Both already existed as site-wide pages; here they are scoped to one
# profession. (Its abbreviations have their own tab — Paths::GlossariesController.)
class Paths::LibrariesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    @entries = ResourceLibrary.for(path: @path)
    @calculators = Calculator.for_path(@path)

    # Render-free 304 for re-crawls: the page changes with the profession's
    # resources or a deploy that registers a calculator.
    if Current.user.nil?
      last_modified = [ @path.updated_at, Resource.maximum(:updated_at) ].compact.max
      fresh_when etag: [ @entries.size, @calculators.map(&:slug) ], last_modified: last_modified
    end
  end
end
