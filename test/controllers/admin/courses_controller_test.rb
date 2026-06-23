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

  # ── Slug lock (SEO) ──

  test "the slug of a published course cannot be changed" do
    original = courses(:el_basics).slug
    patch admin_course_path(courses(:el_basics)),
      params: { course: { slug: "vzlomannyy", description: "Новое описание" } }
    courses(:el_basics).reload
    assert_equal original, courses(:el_basics).slug
    assert_equal "Новое описание", courses(:el_basics).description
  end

  test "the slug of a draft course can be changed" do
    patch admin_course_path(courses(:draft_course)), params: { course: { slug: "pereimenovannyy" } }
    assert_equal "pereimenovannyy", courses(:draft_course).reload.slug
  end
end
