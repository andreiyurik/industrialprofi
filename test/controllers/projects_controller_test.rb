require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "index lists practice lessons as project cards" do
    get projects_path
    assert_response :success
    assert_select ".project-card", 2
    assert_match lessons(:praktika_shchitok).title, response.body
    assert_match lessons(:praktika_svarka).title, response.body
    assert_match I18n.t("projects.found", count: 2), response.body
  end

  test "index hides regular lessons and unpublished paths" do
    get projects_path
    assert_no_match lessons(:pteep).title, response.body
    assert_no_match(/Черновик/, response.body)
  end

  test "cards carry difficulty badges" do
    get projects_path
    assert_select ".badge--diff-advanced", text: I18n.t("lessons.difficulty.advanced")
    assert_select ".badge--diff-beginner", text: I18n.t("lessons.difficulty.beginner")
  end

  test "filters by difficulty" do
    get projects_path(difficulty: "beginner")
    assert_select ".project-card", 1
    assert_match lessons(:praktika_svarka).title, response.body
    assert_no_match lessons(:praktika_shchitok).title, response.body
  end

  test "filters by path" do
    get projects_path(path: paths(:electrician).slug)
    assert_select ".project-card", 1
    assert_match lessons(:praktika_shchitok).title, response.body
    assert_no_match lessons(:praktika_svarka).title, response.body
  end

  test "empty filter combination offers a reset link" do
    get projects_path(path: paths(:welder).slug, difficulty: "advanced")
    assert_select ".project-card", 0
    assert_match I18n.t("projects.reset_filters"), response.body
  end

  test "unknown filter values are ignored" do
    get projects_path(path: "nope", difficulty: "extreme")
    assert_response :success
    assert_select ".project-card", 2
  end

  test "focus path's projects sort first" do
    users(:member).lesson_completions.create!(lesson: lessons(:svarka_intro))

    sign_in_as users(:member)
    get projects_path
    assert_operator response.body.index(lessons(:praktika_svarka).title),
                    :<, response.body.index(lessons(:praktika_shchitok).title)
  end

  test "bookmark toggles appear only for signed-in users" do
    get projects_path
    assert_select ".bookmark-btn", false

    sign_in_as users(:member)
    get projects_path
    assert_select ".project-card-wrap .bookmark-btn", 2
    assert_match I18n.t("projects.saved_filter"), response.body
  end

  test "saved filter shows only bookmarked tasks" do
    users(:member).lesson_bookmarks.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get projects_path(saved: "1")
    assert_select ".project-card", 1
    assert_match lessons(:praktika_shchitok).title, response.body
    assert_select ".bookmark-btn--on"
  end

  test "saved filter with no bookmarks explains itself" do
    sign_in_as users(:member)
    get projects_path(saved: "1")
    assert_select ".project-card", 0
    assert_match I18n.t("projects.empty_saved"), response.body
  end

  test "saved filter is ignored for signed-out visitors" do
    get projects_path(saved: "1")
    assert_select ".project-card", 2
  end

  test "index shows completion marks for signed-in users" do
    users(:member).lesson_completions.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get projects_path
    assert_response :success
    assert_select ".project-card__done"
  end
end
