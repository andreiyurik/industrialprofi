require "test_helper"

class Admin::LessonLinksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "without auth redirects to sign-in" do
    sign_out
    get admin_lesson_links_path(filter: "ПТЭ")
    assert_redirected_to new_session_path
  end

  test "a plain member is closed out" do
    sign_out
    sign_in_as users(:member)
    get admin_lesson_links_path(filter: "ПТЭ")
    assert_response :redirect
  end

  test "returns matching lessons as prompt items with an internal-link template" do
    lesson = lessons(:pteep)
    get admin_lesson_links_path(filter: lesson.title[0, 4])
    assert_response :success
    assert_match "lexxy-prompt-item", response.body
    assert_match lesson.title, response.body
    assert_match %(href="#{lesson_path(lesson)}"), response.body
    # Stacked menu row: title over a muted profession line (not a squished pair).
    assert_match "lesson-link-item__path", response.body
    assert_match lesson.path.title, response.body
  end

  test "a blank filter returns no items" do
    get admin_lesson_links_path(filter: "")
    assert_response :success
    assert_no_match(/lexxy-prompt-item/, response.body)
  end

  test "an editor may use the picker" do
    sign_out
    sign_in_as users(:editor)
    get admin_lesson_links_path(filter: "ПТЭ")
    assert_response :success
  end
end
