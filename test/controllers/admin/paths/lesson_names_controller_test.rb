require "test_helper"

class Admin::Paths::LessonNamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "update renames a lesson and gives it human ownership" do
    patch admin_path_lesson_name_path(paths(:electrician), lessons(:pteep)), params: { value: "Новое название" }
    assert_response :no_content
    assert_equal "Новое название", lessons(:pteep).reload.title
    assert_equal "human", lessons(:pteep).reload.origin
  end

  test "a blank title is rejected" do
    patch admin_path_lesson_name_path(paths(:electrician), lessons(:pteep)), params: { value: "  " }
    assert_response :unprocessable_entity
    assert_not_equal "", lessons(:pteep).reload.title
  end

  test "an editor cannot rename a lesson in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_lesson_name_path(paths(:welder), lessons(:svarka_intro)), params: { value: "Взлом" }
    assert_response :not_found
    assert_not_equal "Взлом", lessons(:svarka_intro).reload.title
  end
end
