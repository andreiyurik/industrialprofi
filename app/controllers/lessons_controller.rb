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
end
