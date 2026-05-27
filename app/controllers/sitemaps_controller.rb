class SitemapsController < ApplicationController
  def show
    @paths = Path.published.ordered
    @lessons = Lesson.joins(:path).where(paths: { status: "published" }).order(:id)

    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end
end
