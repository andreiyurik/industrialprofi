# One published path per locale, no mirror pages: the wrong locale prefix 301s
# to the same content under the right one.
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

    # Shared by the Теория tab's cards and the overview's outline — same two queries.
    def load_curriculum
      @courses = @path.courses.listable.ordered.to_a
      # [course_id, kind] => count, for the lesson/practice counters.
      @kind_counts = @path.lessons.group(:course_id, :kind).count
    end
end
