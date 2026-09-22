class LessonsController < ApplicationController
  allow_unauthenticated_access

  def show
    # No includes: eager loading would still run for a 304 or .md response that never renders.
    @lesson = Lesson.find_by!(slug: params[:slug])
    @course = @lesson.course
    @path = @lesson.path
    unless @path.locale == params[:locale]
      return redirect_to lesson_path(@lesson, locale: @path.locale), status: :moved_permanently
    end

    @preview = !publicly_visible?(@lesson)
    raise ActiveRecord::RecordNotFound if @preview && !Current.user&.can_edit_path?(@path)

    # Signed-out only: a signed-in page carries completion state last_modified can't capture.
    if Current.user.nil?
      fresh_when last_modified: content_last_modified
      return if performed?
    end

    @lessons_by_stage = @course.lessons.group_by(&:stage)
    @completed_ids = signed_in? ? Current.user.completed_lesson_ids_for_course(@course) : Set.new

    @my_journal_entries =
      @lesson.practice? && signed_in? ? Current.user.journal_entries.where(lesson: @lesson).ordered : []

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end

  private
    def publicly_visible?(lesson)
      lesson.course&.status == "published" && lesson.path&.status == "published"
    end

    # Deliberately broad: any edit to the course/profession revalidates the lesson too.
    def content_last_modified
      [
        @path.lessons.maximum(:updated_at),
        @lesson.resources.maximum(:updated_at),
        @course.updated_at,
        @path.updated_at
      ].compact.max
    end
end
