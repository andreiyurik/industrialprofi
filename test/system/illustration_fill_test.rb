require "application_system_test_case"

# The illustration fill loop end-to-end: the pending box on the reader page
# carries a fill link hidden in the shared cached HTML, revealed only for a
# user who may edit this profession (.lesson--fillable) — a CSS-reveal no
# request test can see. Clicking it lands on the fill screen; uploading swaps
# the placeholder for the image in the article the expert is returned to.
class IllustrationFillTest < ApplicationSystemTestCase
  # gruppy_dopuska on purpose: an anonymous lesson page is cacheable
  # (fresh_when, second-precision Last-Modified) and Chrome keeps its HTTP cache
  # across tests — guest-visiting a lesson another test also guest-visits with a
  # different body can 304 into THAT test's cached page (see lesson_editor_test).
  setup do
    lessons(:gruppy_dopuska).update!(body: <<~MD)
      Перед схемой.

      ![Схема допуска — кто кого допускает](TODO-elektrik-dopusk.png)
      *Рис. 1. Порядок допуска.*

      После схемы.
    MD
  end

  test "a guest sees the pending box but no fill link" do
    visit lesson_path(lessons(:gruppy_dopuska))

    assert_selector ".attachment__missing"
    assert_no_selector ".attachment__fill"
  end

  test "an editor fills the placeholder from the article page" do
    sign_in_as users(:editor)
    resize(390)
    visit lesson_path(lessons(:gruppy_dopuska))
    assert_selector ".attachment__missing"

    find(".attachment__fill").click
    assert_text "Схема допуска — кто кого допускает"

    # Turbo animates navigations with a document view transition (the layout's
    # view-transition meta); its overlay can swallow the submit click. A fresh
    # load of the same URL sidesteps the animation — the flow itself is already
    # proven by the click above.
    visit current_url
    attach_file "illustration[file]", file_fixture("cover.png")
    click_on I18n.t("admin.illustrations.submit")

    # Headless Chrome sometimes swallows the click right after attach_file (no
    # POST reaches the server; elementFromPoint shows nothing covers the
    # button). Fall back to requestSubmit() — the same native submit path.
    unless page.has_text?(I18n.t("admin.illustrations.filled"), wait: 5)
      begin
        page.execute_script("arguments[0].form.requestSubmit()", find("input[type=submit]", wait: 0))
      rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::StaleElementReferenceError
        # the first click was merely slow — the assert below sees it through
      end
    end
    assert_text I18n.t("admin.illustrations.filled"), wait: 10
    assert_selector ".prose-figure img"
    assert_no_selector ".attachment__missing"
  end

  private
    def resize(width)
      page.driver.browser.manage.window.resize_to(width, 900)
    end
end
