class ApplicationController < ActionController::Base
  include Authentication

  # Floors follow the CSS we actually ship (lh units, nesting, :has), not the
  # Rails :modern preset — :modern (Safari 17.2+/Chrome 120+) walled off readers
  # on iOS 16–17.1 and Chrome 109 (the last build for Windows 7, still common in
  # CIS) with a hard 406. A reading platform degrades, it doesn't block.
  allow_browser versions: { safari: 16.5, chrome: 109, firefox: 120, opera: 95, ie: false }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :signup_open?

  private
    # Registration depends entirely on the verification-code email arriving —
    # gate it on the same credential the SMTP settings read, so the "coming
    # soon" notice disappears on its own once `smtp:` is set, no toggle to
    # remember to flip back. Dev/test never touch real SMTP (delivery_method
    # is :test), so they're unaffected.
    def signup_open?
      !Rails.env.production? || Rails.application.credentials.dig(:smtp, :address).present?
    end
end
