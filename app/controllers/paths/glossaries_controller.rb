# The «Словарь» tab of a profession hub: that profession's abbreviations,
# decoded — the same rows the site-wide /glossary shows across professions.
# The tab exists only for professions whose lessons define any (GlossaryTerm).
class Paths::GlossariesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    terms = GlossaryTerm.for_path(@path)
    raise ActiveRecord::RecordNotFound unless terms.exists?

    # Render-free 304 for re-crawls: the page changes with a term or a
    # referenced lesson's title (the /glossary idiom).
    if Current.user.nil?
      fresh_when last_modified: [ @path.updated_at, terms.maximum(:updated_at), Lesson.maximum(:updated_at) ].compact.max
      return if performed?
    end

    @terms = terms.to_a
  end
end
