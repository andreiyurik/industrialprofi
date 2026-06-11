require "test_helper"

class PathsControllerTest < ActionDispatch::IntegrationTest
  test "index returns success" do
    get paths_path
    assert_response :success
  end

  test "index shows only published paths" do
    get paths_path
    assert_match paths(:electrician).title, response.body
    assert_match paths(:welder).title, response.body
    assert_no_match(/Черновик/, response.body)
  end

  test "index shows only paths in the current locale" do
    Path.create!(title: "English Electrician", slug: "english-electrician",
                 description: "US market path", locale: "en", position: 9, status: "published")

    get paths_path
    assert_no_match(/English Electrician/, response.body)
  end

  test "index shows a focus banner to a learner mid-path" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get paths_path
    assert_match "focus-banner", response.body
    assert_match paths(:electrician).title, response.body
  end

  test "index shows no focus banner to visitors" do
    get paths_path
    assert_no_match(/focus-banner/, response.body)
  end

  test "show returns success for published path" do
    get path_path(paths(:electrician))
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "show returns 404 for draft path" do
    get path_path(slug: paths(:draft_path).slug)
    assert_response :not_found
  end

  test "show returns 404 for unknown slug" do
    get path_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "show displays lessons grouped by stage" do
    get path_path(paths(:electrician))
    assert_match lessons(:pteep).title, response.body
    assert_match lessons(:zazemlenie).title, response.body
  end
end
