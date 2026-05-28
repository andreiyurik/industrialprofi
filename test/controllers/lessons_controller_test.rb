require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  test "show returns success for published lesson" do
    get lesson_path(lessons(:pteep))
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "show returns 404 for unknown slug" do
    get lesson_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "show displays resources" do
    get lesson_path(lessons(:pteep))
    assert_match resources(:pteep_doc).title, response.body
  end

  test "show displays prev/next navigation" do
    get lesson_path(lessons(:gruppy_dopuska))
    assert_match lessons(:pteep).title, response.body
    assert_match lessons(:zazemlenie).title, response.body
  end

  test "show markdown format returns raw markdown" do
    get lesson_path(lessons(:pteep), format: :md)
    assert_response :success
    assert_match %r{text/markdown}, response.content_type
    assert_includes response.body, lessons(:pteep).title
    assert_includes response.body, lessons(:pteep).body
  end

  test "show renders markdown in html body" do
    get lesson_path(lessons(:pteep))
    assert_select "div.prose"
  end
end
