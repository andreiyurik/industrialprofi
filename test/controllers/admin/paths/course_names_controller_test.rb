require "test_helper"

class Admin::Paths::CourseNamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "update renames a course" do
    patch admin_path_course_name_path(paths(:electrician), courses(:el_basics)), params: { value: "Электробезопасность" }
    assert_response :no_content
    assert_equal "Электробезопасность", courses(:el_basics).reload.title
  end

  test "a blank title is rejected" do
    patch admin_path_course_name_path(paths(:electrician), courses(:el_basics)), params: { value: "" }
    assert_response :unprocessable_entity
  end

  test "an editor cannot rename a course in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_course_name_path(paths(:welder), courses(:welding_basics)), params: { value: "Взлом" }
    assert_response :not_found
    assert_not_equal "Взлом", courses(:welding_basics).reload.title
  end
end
