module Admin
  # Feeds the Lexxy @-mention picker: given ?filter=<text>, returns matching lessons
  # as <lexxy-prompt-item> HTML so authors insert internal /lessons/:slug links by title.
  class LessonLinksController < BaseController
    LIMIT = 8

    def index
      @lessons = Lesson.title_search(params[:filter]).includes(:path).limit(LIMIT)
      render layout: false
    end
  end
end
