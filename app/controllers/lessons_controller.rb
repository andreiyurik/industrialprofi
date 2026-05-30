class LessonsController < ApplicationController
  def show
    @lesson = Lesson.joins(:path)
                    .where(paths: { status: "published" })
                    .includes(:resources, :path)
                    .find_by!(slug: params[:slug])
    @path = @lesson.path

    respond_to do |format|
      format.html
      format.md { render plain: @lesson.to_markdown, content_type: "text/markdown" }
    end
  end
end
