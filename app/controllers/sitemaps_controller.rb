class SitemapsController < ApplicationController
  allow_unauthenticated_access
  # /robots.txt and /sitemap.xml genuinely live at the domain root.
  skip_before_action :redirect_unlocalized

  # Private/auth areas are crawlable-but-pointless (they redirect to login) —
  # keep crawl budget on the content. Everything else stays allowed by default.
  # /search is disallowed for a different reason: ?q= is an infinite URL space
  # that bypasses every cache — bots would grind the VPS for nothing.
  DISALLOWED = %w[
    /admin /account /dashboard /journal /session /signup
    /passwords /unsubscribe /feedbacks /learning_goal /search
  ].freeze

  def robots
    expires_in 1.day, public: true
    lines = [ "User-agent: *" ]
    # Every bot stays allowed (we WANT search + AI-citation reach); the only
    # throttle is a light crawl-delay for the bursty long tail. Google ignores
    # crawl-delay, so indexing speed is unaffected; Bing/Yandex/misc honour it.
    lines << "Crawl-delay: 10"
    # Disallow matches by prefix, so each locale needs its own line; the bare
    # form covers pre-locale URLs still 301ing from the wild.
    locales = [ nil, *I18n.available_locales ]
    lines.concat(locales.flat_map { |locale| DISALLOWED.map { |path| "Disallow: #{"/#{locale}" if locale}#{path}" } })
    lines << "Sitemap: #{Rails.application.config.x.site.url}/sitemap.xml"
    render plain: lines.join("\n") + "\n"
  end

  def show
    @paths = Path.published.ordered
    # Only professions with tasks get a practice URL — an empty tab isn't a page.
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
