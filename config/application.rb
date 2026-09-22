require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module IndustrialprofiDhh
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :ru
    config.i18n.available_locales = %i[ru en]
    # Fallback keeps a stray missing-key gap readable instead of raising.
    config.i18n.fallbacks = true
    config.i18n.fallbacks = true

    # Moscow is the reference for displayed times and recurring-job firing; storage stays UTC.
    config.time_zone = "Moscow"
  end
end
