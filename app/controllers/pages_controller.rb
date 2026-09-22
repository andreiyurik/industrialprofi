class PagesController < ApplicationController
  allow_unauthenticated_access

  # Private: layout varies by sign-in; Rack::ETag busts the cache when content changes.
  before_action -> { expires_in 1.hour }

  PARTNERS = [].freeze

  # Render order; a tier with no entries is skipped entirely (no empty heading).
  TIER_ORDER = %w[gold silver bronze community].freeze

  def about
  end

  def contribute
  end

  def authors
  end

  def faq
  end

  REFERENCE_LESSON_SLUGS = %w[chtenie-shem-i-ugo soedinenie-provodov sborka-shchita].freeze

  def guide
    @reference_lessons = Lesson.where(slug: REFERENCE_LESSON_SLUGS).ordered
  end

  def roadmap
  end

  def partners
    @partners_by_tier = PARTNERS.group_by { |partner| partner[:tier] }
  end

  def support_us
  end

  def privacy
  end
end
