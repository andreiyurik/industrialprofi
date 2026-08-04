class ApplicationController < ActionController::Base
  include Authentication

  # Floors follow the CSS we actually ship (lh units, nesting, :has), not the
  # Rails :modern preset — :modern (Safari 17.2+/Chrome 120+) walled off readers
  # on iOS 16–17.1 and Chrome 109 (the last build for Windows 7, still common in
  # CIS) with a hard 406. A reading platform degrades, it doesn't block.
  allow_browser versions: { safari: 16.5, chrome: 109, firefox: 120, opera: 95, ie: false }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # The URL's :locale segment is the single source of language truth (the
  # route constrains it to available locales); unscoped endpoints such as
  # /sitemap.xml fall back to the default. The segment is optional only for
  # the router — an unprefixed GET (old links, the first indexed week) 301s
  # to its /ru twin before anything else runs.
  prepend_before_action :redirect_unlocalized
  around_action :switch_locale

  helper_method :signup_open?

  def default_url_options
    { locale: I18n.locale }
  end

  private
    def redirect_unlocalized
      return if params[:locale].present? || !request.get?

      redirect_to "/#{I18n.default_locale}#{request.fullpath}", status: :moved_permanently
    end

    def switch_locale(&)
      I18n.with_locale(params[:locale] || I18n.default_locale, &)
    end
    # Fetches one extra row to learn if a next page/batch exists without a
    # second query, then trims back down to per_page.
    def paginate_window(scope, per_page:)
      records = scope.limit(per_page + 1).to_a
      [ records.first(per_page), records.size > per_page ]
    end

    # Registration depends entirely on the verification-code email arriving —
    # gate it on the same credential the SMTP settings read, so the "coming
    # soon" notice disappears on its own once `smtp:` is set, no toggle to
    # remember to flip back. Dev/test never touch real SMTP (delivery_method
    # is :test), so they're unaffected.
    def signup_open?
      !Rails.env.production? || Rails.application.credentials.dig(:smtp, :address).present?
    end
end
