ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# dartsass writes app/assets/builds/application.css during assets:precompile,
# which `rails test` never runs. On a fresh clone (the directory is gitignored)
# or in CI, the very first page render would die on a missing asset. Build it
# once instead of making everyone learn that by hitting it.
unless Rails.root.join("app/assets/builds/application.css").exist?
  puts "Building stylesheets (app/assets/builds is empty)…"
  system("bin/rails", "dartsass:build", exception: true)
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

module ActionDispatch
  class IntegrationTest
    include SessionTestHelper

    # Every route now carries a :locale prefix; URL helpers called from test
    # code (unlike those inside the app) have no request to inherit it from.
    # The writer reaches the integration Session — helper calls delegate there.
    setup do
      self.default_url_options = { locale: I18n.default_locale }
    end
  end
end
