class LessonsController < ApplicationController
  def show
    @lesson = Lesson.joins(:path)
                    .where(paths: { status: "published" })
                    .includes(:resources, :path)
                    .find_by!(slug: params[:slug])
    @path = @lesson.path
    @siblings = @path.lessons.ordered.to_a
    @lessons_by_stage = @siblings.group_by(&:stage)

    current_index = @siblings.index { |l| l.id == @lesson.id }
    @prev_lesson = current_index && current_index > 0 ? @siblings[current_index - 1] : nil
    @next_lesson = current_index && current_index < @siblings.size - 1 ? @siblings[current_index + 1] : nil

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end
end
