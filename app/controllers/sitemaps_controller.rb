class SitemapsController < ApplicationController
  allow_unauthenticated_access

  # Private/auth areas are crawlable-but-pointless (they redirect to login) —
  # keep crawl budget on the content. Everything else stays allowed by default.
  DISALLOWED = %w[
    /admin /account /dashboard /journal /session /signup
    /passwords /unsubscribe /feedbacks /learning_goal
  ].freeze

  def robots
    expires_in 1.day, public: true
    lines = [ "User-agent: *" ]
    lines.concat(DISALLOWED.map { |path| "Disallow: #{path}" })
    lines << "Sitemap: #{Rails.application.config.x.site.url}/sitemap.xml"
    render plain: lines.join("\n") + "\n"
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
