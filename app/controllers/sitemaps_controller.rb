class SitemapsController < ApplicationController
  allow_unauthenticated_access
  # /robots.txt and /sitemap.xml genuinely live at the domain root.
  skip_before_action :redirect_unlocalized

  # /search is disallowed: ?q= is an infinite URL space that bypasses cache and would grind the VPS.
  DISALLOWED = %w[
    /admin /account /dashboard /journal /session /signup
    /passwords /unsubscribe /feedbacks /learning_goal /search
  ].freeze

  def robots
    expires_in 1.day, public: true
    lines = [ "User-agent: *" ]
    lines << "Crawl-delay: 10"
    # Prefix match needs a line per locale; the bare form covers pre-locale URLs still 301ing in.
    locales = [ nil, *I18n.available_locales ]
    lines.concat(locales.flat_map { |locale| DISALLOWED.map { |path| "Disallow: #{"/#{locale}" if locale}#{path}" } })
    lines << "Sitemap: #{Rails.application.config.x.site.url}/sitemap.xml"
    render plain: lines.join("\n") + "\n"
  end

  def show
    @paths = Path.published.ordered
    @practice_path_ids = Lesson.practice.where(path_id: @paths.map(&:id)).distinct.pluck(:path_id).to_set
    @glossary_path_ids = GlossaryTerm.joins(:lesson).distinct.pluck("lessons.path_id").to_set
    @courses = Course.published.joins(:path).where(paths: { status: "published" }).includes(:path).order(:id)
    @lessons = Lesson.joins(course: :path)
                     .where(courses: { status: "published" }, paths: { status: "published" })
                     .includes(:path).order(:id)

    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end
end
