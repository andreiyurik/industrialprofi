require "application_system_test_case"

# The illustration fill loop end-to-end: the pending box on the reader page
# carries a fill link hidden in the shared cached HTML, revealed only for a
# user who may edit this profession (.lesson--fillable) — a CSS-reveal no
# request test can see. Clicking it lands on the fill screen; uploading swaps
# the placeholder for the image, and the expert is returned to the queue.
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
    # A cold admin page plus the view transition can outlast the 2 s default on a CI runner.
    assert_text "Схема допуска — кто кого допускает", wait: 10

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
    filled = I18n.t("admin.illustrations.filled", lesson: lessons(:gruppy_dopuska).title)
    unless page.has_text?(filled, wait: 5)
      begin
        page.execute_script("arguments[0].form.requestSubmit()", find("input[type=submit]", wait: 0))
      rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::StaleElementReferenceError
        # the first click was merely slow — the assert below sees it through
      end
    end
    assert_text filled, wait: 10
    assert_selector "img.illustration-card__thumb"

    visit lesson_path(lessons(:gruppy_dopuska))
    assert_selector ".prose-figure img"
    assert_selector ".prose-figure__caption", text: "Рис. 1. Порядок допуска."
    assert_no_selector ".attachment__missing"
  end

  test "saving the lesson editor keeps placeholders, filled images and callouts" do
    lesson = lessons(:gruppy_dopuska)
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("cover.png").open, filename: "pribor.png", content_type: "image/png")
    filled = "![Прибор](#{Rails.application.routes.url_helpers.rails_service_blob_proxy_path(blob.signed_id, blob.filename)})\n*Рис. 2. Прибор.*"
    lesson.update!(body: lesson.body + "\n![Щит](placeholder: щит в разрезе, вводной автомат сверху)\n\n#{filled}\n\n> [!ПРОВЕРЬ]\n> Кто выдаёт допуск?\n")
    sign_in_as users(:admin)

    visit edit_admin_lesson_path(lesson)
    assert_selector "lexxy-editor[connected]"
    click_on I18n.t("admin.save")
    assert_text I18n.t("flash.lesson_updated")

    assert lesson.reload.rich_body.present?
    assert_equal [ [ "TODO-elektrik-dopusk.png", "Схема допуска — кто кого допускает" ], [ "placeholder: щит в разрезе, вводной автомат сверху", "Щит" ] ],
                 lesson.illustration_slots.map { [ it.src, it.brief ] }
    assert_equal [ [ blob, "Рис. 2. Прибор." ] ], blob_attachments(lesson)

    # A real edit makes Lexxy re-export its own document rather than echo ours.
    visit edit_admin_lesson_path(lesson)
    find("lexxy-editor#lesson_rich_body[connected] [contenteditable]", match: :first).send_keys(:end, " Правка.")
    click_on I18n.t("admin.save")
    assert_text I18n.t("flash.lesson_updated")

    assert_equal [ "TODO-elektrik-dopusk.png", "placeholder: щит в разрезе, вводной автомат сверху" ],
                 lesson.reload.illustration_slots.map(&:src)
    assert_equal [ [ blob, "Рис. 2. Прибор." ] ], blob_attachments(lesson)
    assert_includes lesson.rich_body.to_plain_text, "Правка."
    assert_match %r{<blockquote>.*\[!ПРОВЕРЬ\]}m, lesson.rich_body.body.to_html
  end

  private
    def blob_attachments(lesson)
      lesson.rich_body.body.attachments.select { it.attachable.is_a?(ActiveStorage::Blob) }.map { [ it.attachable, it.caption ] }
    end

    def resize(width)
      page.driver.browser.manage.window.resize_to(width, 900)
    end
end
