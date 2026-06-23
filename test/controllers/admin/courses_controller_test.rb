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

  # Guards the "Back\"> + translation missing" bug: a missing key makes t()
  # return an HTML span whose quotes break the aria-label attribute.
  test "edit renders with a proper back label, no missing translations" do
    get edit_admin_course_path(courses(:el_basics))
    assert_response :success
    assert_no_match(/translation.missing/i, response.body)
    assert_select "a.admin-header__back[aria-label=?]", I18n.t("admin.back")
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

  # path_id is create-only: permitting it on update would let a scoped editor
  # push a course into a profession they don't own.
  test "path_id is ignored on update — a course never moves professions" do
    course = courses(:el_basics) # belongs to the electrician profession
    patch admin_course_path(course),
      params: { course: { path_id: paths(:welder).id, title: "Тронули" } }
    course.reload
    assert_equal paths(:electrician), course.path, "path stays put"
    assert_equal "Тронули", course.title, "other fields still save"
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
