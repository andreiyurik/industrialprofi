require "application_system_test_case"

class LessonImagesTest < ApplicationSystemTestCase
  test "a lesson figure opens full-screen in a zoomable lightbox" do
    lessons(:pteep).update!(
      body: "Вступление.\n\n![схема](/lesson-images/test.svg)\n\n*Рис. 1. Тестовая схема.*"
    )

    visit lesson_path(lessons(:pteep))

    # Image and caption are one tight figure, caption adopted as <figcaption>.
    assert_selector ".prose-figure img"
    assert_selector ".prose-figure__caption", text: "Рис. 1. Тестовая схема."

    # The zoom affordance is injected by the lightbox Stimulus controller —
    # its presence proves the controller connected.
    assert_selector ".prose-figure__zoom"

    # Clicking the image opens the full-screen viewer.
    find(".prose-figure img").click
    assert_selector "dialog.lightbox[open] img.lightbox__img"

    # Clicking the image again toggles full-resolution zoom.
    find("dialog.lightbox img.lightbox__img").click
    assert_selector "dialog.lightbox.lightbox--zoomed"
  end
end
