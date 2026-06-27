class LessonsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lesson = Lesson.includes(:resources, :course, :path).find_by!(slug: params[:slug])
    @course = @lesson.course
    @path = @lesson.path
    # Published content is public; an editor/admin may PREVIEW their own drafts
    # (so "view live" works while authoring). Everyone else gets a 404.
    @preview = !publicly_visible?(@lesson)
    raise ActiveRecord::RecordNotFound if @preview && !Current.user&.can_edit_path?(@path)

    # Crawlers and signed-out visitors get a conditional GET: re-requesting an
    # unchanged lesson returns 304 and skips rendering entirely — the cheapest
    # possible response, and a crawl-efficiency signal Google rewards. Only when
    # signed out: a signed-in page carries personalization (completion state)
    # that last_modified can't capture, so they always render fresh.
    if Current.user.nil?
      fresh_when last_modified: content_last_modified
      return if performed?
    end

    # Sidebar is scoped to the current course (TOP-style course contents).
    @lessons_by_stage = @course.lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for_course(@course) : Set.new

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end

  private
    def publicly_visible?(lesson)
      lesson.course&.status == "published" && lesson.path&.status == "published"
    end

    # The newest timestamp among everything an anonymous lesson page shows: the
    # lesson and its siblings (sidebar, prev/next), its links, and the course /
    # profession. Conservative on purpose — any edit in the profession revalidates,
    # which is fine since lessons are read far more than they change.
    def content_last_modified
      [
        @path.lessons.maximum(:updated_at),
        @lesson.resources.maximum(:updated_at),
        @course.updated_at,
        @path.updated_at
      ].compact.max
    end
end
