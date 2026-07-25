module Admin
  # Feeds the Lexxy @-mention picker in the lesson editor: given ?filter=<text>,
  # returns matching lessons as <lexxy-prompt-item> HTML so an author can insert
  # an internal /lessons/:slug link by title instead of hand-writing the slug —
  # the wiki fabric, minus the broken links content:audit used to catch after.
  class LessonLinksController < BaseController
    LIMIT = 8

    def index
      @lessons = Lesson.title_search(params[:filter]).includes(:path).limit(LIMIT)
      render layout: false
    end
  end
end
