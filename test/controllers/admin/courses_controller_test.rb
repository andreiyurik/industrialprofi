require "test_helper"

class Admin::CoursesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "index as a member is not allowed" do
    sign_out
    sign_in_as users(:member)
    get admin_courses_path
    assert_redirected_to root_path
  end

  test "index returns success" do
    get admin_courses_path
    assert_response :success
  end

  test "new renders" do
    get new_admin_course_path
    assert_response :success
  end

  test "create adds a course under a path with an appended position" do
    assert_difference -> { paths(:electrician).courses.count }, 1 do
      post admin_courses_path, params: { course: {
        path_id: paths(:electrician).id, title: "Курс Монтажа", status: "published"
      } }
    end
    course = Course.find_by!(title: "Курс Монтажа")
    assert_redirected_to edit_admin_course_path(course)
    assert_equal paths(:electrician), course.path
    assert_equal "published", course.status
    assert_equal "human", course.origin
    assert_equal "kurs-montazha", course.slug
    assert course.position.positive?
  end

  test "an editor cannot publish a new course" do
    sign_out
    sign_in_as users(:editor)
    post admin_courses_path, params: { course: {
      path_id: paths(:electrician).id, title: "Черновой Курс", status: "published"
    } }
    assert_equal "draft", Course.find_by!(title: "Черновой Курс").status
  end

  test "create without a path re-renders" do
    post admin_courses_path, params: { course: { title: "Сирота" } }
    assert_response :unprocessable_entity
  end
end
