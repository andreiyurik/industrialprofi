require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Some boxes (Ubuntu/WSL) ship /usr/bin/chromium-browser as a snap stub that
  # exits immediately — Selenium Manager happily resolves it and every session
  # dies with "Chrome instance exited". Prefer an explicit CHROME_BIN, then the
  # newest Chrome for Testing that Selenium Manager itself cached; with a real
  # Chrome installed neither exists and the default resolution just works.
  CHROME_BIN = ENV["CHROME_BIN"].presence ||
    Dir[File.expand_path("~/.cache/selenium/chrome/linux64/*/chrome")]
      .max_by { |path| Gem::Version.new(path[/linux64\/([\d.]+)/, 1]) }

  # Chrome's sandbox needs privileges that containers/WSL don't grant, and
  # /dev/shm there is too small for a renderer — without these two flags the
  # browser exits before the session is created.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.binary = CHROME_BIN if CHROME_BIN
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
  end
end
