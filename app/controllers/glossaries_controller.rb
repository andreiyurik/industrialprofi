class GlossariesController < ApplicationController
  allow_unauthenticated_access

  # The full crawlable dictionary across professions. One profession's terms
  # live on its hub «Словарь» tab — the chips lead there, and the old
  # ?path=<slug> page 301s there too.
  def show
    if params[:path].present?
      path = Path.published.localized.find_by!(slug: params[:path])
      raise ActiveRecord::RecordNotFound unless path.has_glossary?
      return redirect_to path_glossary_path(path), status: :moved_permanently
    end

    # Render-free 304 for re-crawls (the lessons idiom): the page only changes
    # when a term or a referenced path/lesson title does. Signed-in readers
    # skip this — their page varies (the feedback link target).
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
