# The profession hub: paths#show and its tabs all open on one published path
# and share the locale rule — content lives in exactly ONE locale, so the wrong
# prefix 301s to the same page under the right one, never a thin mirror.
module PathScoped
  extend ActiveSupport::Concern

  private
    def set_path
      @path = Path.published.find_by!(slug: params[:path_slug] || params[:slug])
      return if @path.locale == params[:locale]

      redirect_to url_for(locale: @path.locale), status: :moved_permanently
    end

    def set_progress
      @progress = Path::Progress.for(@path, Current.user)
    end

    # The chapters with their lesson/practice counts — the «Теория» tab's cards
    # and the overview's outline read the same two queries.
    def load_curriculum
      @courses = @path.courses.listable.ordered.to_a
      # [course_id, kind] => count, for the lesson/practice counters.
      @kind_counts = @path.lessons.group(:course_id, :kind).count
    end
end
