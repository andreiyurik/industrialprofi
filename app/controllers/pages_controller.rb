class PagesController < ApplicationController
  allow_unauthenticated_access

  # Curated, founder-managed partner list — NOT user-generated, so no disk/abuse
  # concern (logos are a small, bounded, hand-picked set). Empty until the first
  # real partner: the view then shows an invitation, never an empty roster, and
  # only ever renders tiers that actually have entries. Entry shape:
  #   { name:, url:, logo: (optional asset filename), tier: }  tier ∈ TIER_ORDER
  PARTNERS = [].freeze

  # Render order; a tier with no entries is skipped entirely (no empty heading).
  TIER_ORDER = %w[gold silver bronze community].freeze

  def about
  end

  def contribute
  end

  def faq
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
