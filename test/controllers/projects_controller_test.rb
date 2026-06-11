require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "index lists practice lessons grouped by path" do
    get projects_path
    assert_response :success
    assert_match lessons(:praktika_shchitok).title, response.body
    assert_match paths(:electrician).title, response.body
  end

  test "index hides regular lessons and unpublished paths" do
    get projects_path
    assert_no_match lessons(:pteep).title, response.body
    assert_no_match(/Черновик/, response.body)
  end

  test "index marks the focus path group" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get projects_path
    assert_match I18n.t("projects.focus_badge"), response.body
  end

  test "index shows completion marks for signed-in users" do
    users(:member).lesson_completions.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get projects_path
    assert_response :success
    assert_match "curriculum__lesson--done", response.body
    assert_match "1/1", response.body
  end
end
