class SitemapsController < ApplicationController
  def robots
    expires_in 1.day, public: true
    render plain: "User-agent: *\nAllow: /\nSitemap: #{Rails.application.config.x.site.url}/sitemap.xml\n"
  end

  def show
    @paths = Path.published.ordered
    @lessons = Lesson.joins(:path).where(paths: { status: "published" }).order(:id)

    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end
end
