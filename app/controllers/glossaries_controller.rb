class GlossariesController < ApplicationController
  allow_unauthenticated_access

  # Full cross-profession dictionary; a profession's own terms live on its «Словарь»
  # tab — the old ?path=<slug> page 301s there too.
  def show
    if params[:path].present?
      path = Path.published.localized.find_by!(slug: params[:path])
      raise ActiveRecord::RecordNotFound unless path.has_glossary?
      return redirect_to path_glossary_path(path), status: :moved_permanently
    end

    # 304 for re-crawls: changes only with a term or referenced title. Signed-in
    # readers skip this — their page varies (feedback link target).
    if Current.user.nil?
      fresh_when last_modified: [
        GlossaryTerm.maximum(:updated_at),
        Path.maximum(:updated_at),
        Lesson.maximum(:updated_at)
      ].compact.max
      return if performed?
    end

    @groups = GlossaryTerm.by_path
  end
end
