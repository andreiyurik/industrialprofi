class GlossariesController < ApplicationController
  allow_unauthenticated_access

  # Without ?path — the full crawlable dictionary; with ?path=<slug> — one
  # profession's focused page (the /resources?path= pattern). Chips navigate
  # between the two, so «выбрал профессию — видишь только её» costs one click
  # and the default page keeps its SEO weight.
  def show
    if params[:path].present?
      @path = Path.published.localized.find_by!(slug: params[:path])
      raise ActiveRecord::RecordNotFound unless Glossary.path_slugs.include?(@path.slug)
    end

    # Render-free 304 for re-crawls (the lessons idiom): the page only changes
    # when the registry file or a referenced path/lesson title does. Signed-in
    # readers skip this — their page varies (the feedback link target).
    if Current.user.nil?
      fresh_when last_modified: [
        File.mtime(Rails.root.join("config/glossary.yml")),
        Path.maximum(:updated_at),
        Lesson.maximum(:updated_at)
      ].compact.max
      return if performed?
    end

    # Chips always show every profession (with counts), whatever the filter.
    @all_groups = Glossary.grouped
    @groups = @path ? @all_groups.select { |path, _terms| path == @path } : @all_groups
  end
end
