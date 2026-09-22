class ApplicationController < ActionController::Base
  include Authentication

  # Below Rails' :modern preset: that floor 406s iOS 16-17.1 and Chrome 109, still common in CIS.
  allow_browser versions: { safari: 16.5, chrome: 109, firefox: 120, opera: 95, ie: false }

  stale_when_importmap_changes

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
    # Peeks one extra row to detect a next page without a second query.
    def paginate_window(scope, per_page:)
      records = scope.limit(per_page + 1).to_a
      [ records.first(per_page), records.size > per_page ]
    end

    # Gated on the SMTP credential itself, not a separate toggle; dev/test stay open.
    def signup_open?
      !Rails.env.production? || Rails.application.credentials.dig(:smtp, :address).present?
    end
end
