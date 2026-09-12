require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include BulletInstrumentation

  # Same reason as in test_helper: URL helpers in test code need the locale.
  # System tests resolve helpers through a private per-test object that never
  # consults the test class (ActionDispatch::SystemTestCase#url_helpers), so
  # the locale is taught to that object itself.
  private def url_helpers
    super.tap do |helpers|
      def helpers.default_url_options
        { locale: I18n.default_locale }
      end
    end
  end

  # Some boxes (Ubuntu/WSL) ship /usr/bin/chromium-browser as a snap stub that
  # exits immediately — Selenium Manager happily resolves it and every session
  # dies with "Chrome instance exited". Prefer an explicit CHROME_BIN, then the
  # newest Chrome for Testing that Selenium Manager itself cached; with a real
  # Chrome installed neither exists and the default resolution just works.
  CHROME_BIN = ENV["CHROME_BIN"].presence ||
    Dir[File.expand_path("~/.cache/selenium/chrome/linux64/*/chrome")]
      .max_by { |path| Gem::Version.new(path[/linux64\/([\d.]+)/, 1]) }

  # Same story for chromedriver: Selenium Manager re-resolves it over the
  # network once its metadata cache expires (hourly), which kills offline/
  # sandboxed runs. Pointing Service.driver_path at the newest cached driver
  # skips the manager entirely; unset when nothing is cached yet.
  CHROMEDRIVER_BIN =
    Dir[File.expand_path("~/.cache/selenium/chromedriver/linux64/*/chromedriver")]
      .max_by { |path| Gem::Version.new(path[/linux64\/([\d.]+)/, 1]) }
  Selenium::WebDriver::Chrome::Service.driver_path = CHROMEDRIVER_BIN if CHROMEDRIVER_BIN

  # Chrome's sandbox needs privileges that containers/WSL don't grant, and
  # /dev/shm there is too small for a renderer — without these two flags the
  # browser exits before the session is created.
  SCREEN_SIZE = [ 1400, 1400 ]

  driven_by :selenium, using: :headless_chrome, screen_size: SCREEN_SIZE do |options|
    options.binary = CHROME_BIN if CHROME_BIN
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    # Turbo animates every navigation through the View Transitions API, and
    # while one runs the browser paints a snapshot above the page: a real click
    # lands in the snapshot, does nothing and raises nothing — invisible on a
    # fast machine, flaky on a slow one. The app already drops the animation
    # under reduced motion (transitions.css), so asking the browser for it
    # makes clicks deterministic while still exercising shipped CSS. A test
    # that is ABOUT motion asks for it back with `with_motion`.
    options.add_argument("--force-prefers-reduced-motion")
  end

  # Four self-hosted faces load after first paint, and a face swapping reflows
  # every row on the page. Selenium computes an element's centre, then clicks
  # it: a reflow in between drops the click on whatever moved into that spot —
  # no event on the target, and no error either. Wait for the fonts first.
  def visit(*)
    super.tap do
      page.document.synchronize(errors: [ Capybara::ExpectationNotMet ]) do
        raise Capybara::ExpectationNotMet, "fonts still loading" unless page.evaluate_script("document.fonts.status") == "loaded"
      end
    end
  end

  # Emulate a viewer who did not ask for reduced motion — for the one test whose
  # subject IS an animation.
  def with_motion
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia",
      features: [ { name: "prefers-reduced-motion", value: "no-preference" } ])
    yield
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [])
  end

  # Sign in through the real form. Waits on LEAVING the login page rather than on
  # the submit button disappearing: a negative assertion can match the old body
  # before Turbo swaps it in, which made this flake only in a full suite run. The
  # destination varies (post_authenticating_url), so the path is what we assert.
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: password
    find(".auth__submit").click
    assert_no_current_path new_session_path, wait: 10
  end
end
