require "application_system_test_case"

class IconPickerTest < ApplicationSystemTestCase
  test "an editor picks a chapter emblem from the grid" do
    sign_in_as users(:admin)

    course = courses(:el_basics)
    course.update!(icon: nil)
    visit edit_admin_course_path(course)

    # Blank is preselected and shows what the chapter currently inherits.
    assert_checked_field "course_icon_", visible: false
    assert_selector ".icon-picker__option--blank .icon--#{course.path.emblem}"

    choose "course_icon_toolbox-light", allow_label_click: true
    find(".admin-form__actions input[type=submit]").click

    # Wait for the redirect before reading the row, or the assertion races the save.
    assert_text I18n.t("flash.course_updated")
    assert_equal "toolbox-light", course.reload.icon
    assert_checked_field "course_icon_toolbox-light", visible: false
  end

  test "the whole set is on screen — no scrolling inside the picker" do
    sign_in_as users(:admin)
    visit edit_admin_course_path(courses(:el_basics))

    overflow = page.evaluate_script(
      "(() => { const e = document.querySelector('.icon-picker');" \
      "return e.scrollHeight - e.clientHeight; })()"
    )
    assert_equal 0, overflow, "внутри выбора эмблемы появился скролл"
    assert_selector ".icon-picker__option--blank", visible: true
  end
end
