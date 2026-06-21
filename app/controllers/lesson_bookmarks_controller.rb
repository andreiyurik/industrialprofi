class LessonBookmarksController < ApplicationController
  before_action :set_lesson

  def create
    Current.user.lesson_bookmarks.create_or_find_by!(lesson: @lesson)
    respond
  end

  def destroy
    Current.user.lesson_bookmarks.destroy_by(lesson: @lesson)
    @remaining = Current.user.lesson_bookmarks.count
    respond
  end

  private
    def set_lesson
      @lesson = Lesson.joins(course: :path)
                      .where(courses: { status: "published" }, paths: { status: "published" })
                      .find_by!(slug: params[:lesson_slug])
    end

    def respond
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: lesson_path(@lesson) }
      end
    end
end
