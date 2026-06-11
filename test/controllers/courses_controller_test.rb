require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  test "show returns success for a published course" do
    get course_path(courses(:el_basics))
    assert_response :success
    assert_match courses(:el_basics).title, response.body
  end

  test "show lists the course's lessons" do
    get course_path(courses(:el_basics))
    assert_match lessons(:pteep).title, response.body
    assert_match lessons(:gruppy_dopuska).title, response.body
  end

  test "show returns 404 for a coming-soon course" do
    get course_path(slug: courses(:el_relay_soon).slug)
    assert_response :not_found
  end

  test "show returns 404 for a draft course under an unpublished path" do
    get course_path(slug: courses(:draft_course).slug)
    assert_response :not_found
  end

  test "show returns 404 for unknown slug" do
    get course_path(slug: "nonexistent")
    assert_response :not_found
  end
end
