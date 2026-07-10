require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "index lists practice lessons grouped by profession" do
    get projects_path
    assert_response :success
    assert_select ".project-tile", 2
    assert_select ".project-group", 2
    assert_select ".project-group__heading", text: /#{paths(:electrician).title}/
    assert_match "Сборка распределительного щитка", response.body
    assert_match "Первый сварной шов", response.body
    assert_match I18n.t("projects.found", count: 2), response.body
  end

  test "row titles drop the redundant practice prefix" do
    get projects_path
    assert_no_match(/Практика: сборка/, response.body)
  end

  test "index hides regular lessons and unpublished paths" do
    get projects_path
    assert_no_match lessons(:pteep).title, response.body
    assert_no_match(/Черновик/, response.body)
  end

  test "difficulty wedges live in the filter chips, not on the tiles" do
    get projects_path
    assert_select ".filter-chip .difficulty-mark--beginner"
    assert_select ".filter-chip .difficulty-mark--advanced"
    assert_select ".project-tile [class*='difficulty']", false
  end

  test "filters by difficulty" do
    get projects_path(difficulty: "beginner")
    assert_select ".project-tile", 1
    assert_match "Первый сварной шов", response.body
    assert_no_match(/Сборка распределительного щитка/, response.body)
  end

  test "filters by path" do
    get projects_path(path: paths(:electrician).slug)
    assert_select ".project-tile", 1
    assert_match "Сборка распределительного щитка", response.body
    assert_no_match(/Первый сварной шов/, response.body)
  end

  test "empty filter combination offers a reset link" do
    get projects_path(path: paths(:welder).slug, difficulty: "advanced")
    assert_select ".project-tile", 0
    assert_match I18n.t("projects.reset_filters"), response.body
  end

  test "unknown filter values are ignored" do
    get projects_path(path: "nope", difficulty: "extreme")
    assert_response :success
    assert_select ".project-tile", 2
  end

  test "focus path's group sorts first" do
    users(:member).lesson_completions.create!(lesson: lessons(:svarka_intro))

    sign_in_as users(:member)
    get projects_path
    assert_operator response.body.index("Первый сварной шов"),
                    :<, response.body.index("Сборка распределительного щитка")
  end

  test "bookmark toggles appear only for signed-in users" do
    get projects_path
    assert_select ".bookmark-btn", false

    sign_in_as users(:member)
    get projects_path
    assert_select ".project-tile-wrap .bookmark-btn", 2
    assert_match I18n.t("projects.saved_filter"), response.body
  end

  test "saved filter shows only bookmarked tasks" do
    users(:member).lesson_bookmarks.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get projects_path(saved: "1")
    assert_select ".project-tile", 1
    assert_match "Сборка распределительного щитка", response.body
    assert_select ".bookmark-btn--on"
  end

  test "saved filter with no bookmarks explains itself" do
    sign_in_as users(:member)
    get projects_path(saved: "1")
    assert_select ".project-tile", 0
    assert_match I18n.t("projects.empty_saved"), response.body
  end

  test "saved filter is ignored for signed-out visitors" do
    get projects_path(saved: "1")
    assert_select ".project-tile", 2
  end

  test "anonymous visitors revalidate with a 304 instead of a re-render" do
    get projects_path
    last_modified = response.headers["Last-Modified"]
    assert last_modified.present?

    get projects_path, headers: { "HTTP_IF_MODIFIED_SINCE" => last_modified }
    assert_response :not_modified
  end

  test "signed-in pages are personalized and never served as 304" do
    get projects_path
    last_modified = response.headers["Last-Modified"]

    sign_in_as users(:member)
    get projects_path, headers: { "HTTP_IF_MODIFIED_SINCE" => last_modified }
    assert_response :success
  end

  test "index shows completion marks for signed-in users" do
    users(:member).lesson_completions.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get projects_path
    assert_response :success
    assert_select ".project-tile--done", 1
    # the electrician set (1 task) is closed -> green counter; welder's is not
    assert_select ".project-group__count--complete", text: "1 из 1"
    assert_select ".project-group__count", text: "0 из 1"
  end

  test "group counters are not shown to guests" do
    get projects_path
    assert_select ".project-group__count", false
  end
end
