class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def robots
    expires_in 1.day, public: true
    render plain: "User-agent: *\nAllow: /\nSitemap: #{Rails.application.config.x.site.url}/sitemap.xml\n"
  end

  def show
    @paths = Path.published.ordered
    @courses = Course.published.joins(:path).where(paths: { status: "published" }).order(:id)
    @lessons = Lesson.joins(course: :path)
                     .where(courses: { status: "published" }, paths: { status: "published" })
                     .order(:id)

    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end
end
