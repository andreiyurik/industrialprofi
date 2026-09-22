# «Словарь» tab: one profession's abbreviations, same rows /glossary shows across all.
# Exists only for professions whose lessons define any.
class Paths::GlossariesController < ApplicationController
  include PathScoped

  allow_unauthenticated_access
  before_action :set_path, :set_progress

  def show
    terms = GlossaryTerm.for_path(@path)
    raise ActiveRecord::RecordNotFound unless terms.exists?

    # 304 for re-crawls: changes with a term or referenced lesson title (the /glossary idiom).
    if Current.user.nil?
      fresh_when last_modified: [ @path.updated_at, terms.maximum(:updated_at), Lesson.maximum(:updated_at) ].compact.max
      return if performed?
    end

    @terms = terms.to_a
  end
end
