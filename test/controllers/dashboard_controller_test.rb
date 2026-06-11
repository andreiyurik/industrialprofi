require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "signed-in user landing on root is sent to the dashboard" do
    sign_in_as users(:member)
    get root_path
    assert_redirected_to dashboard_path
  end

  test "catalog stays reachable at /paths when signed in" do
    sign_in_as users(:member)
    get paths_path
    assert_response :success
  end

  test "shows empty state without completions" do
    sign_in_as users(:member)
    get dashboard_path
    assert_response :success
    assert_match I18n.t("dashboard.browse_paths"), response.body
  end

  test "shows started path with continue link to next lesson" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
    assert_match lesson_path(lessons(:gruppy_dopuska)), response.body
  end

  test "focus path is the hero; other started paths are listed quietly" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep), created_at: 2.days.ago)
    users(:member).lesson_completions.create!(lesson: lessons(:svarka_intro), created_at: 1.hour.ago)

    sign_in_as users(:member)
    get dashboard_path
    assert_match "dashboard-path--focus", response.body
    assert_match I18n.t("dashboard.focus_title"), response.body
    assert_match I18n.t("dashboard.other_paths"), response.body
  end

  test "does not suggest new paths to a learner who already started one" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_no_match(/#{I18n.t("dashboard.suggested")}/, response.body)
  end

  test "shows activity heatmap once there is activity" do
    sign_in_as users(:member)
    get dashboard_path
    assert_no_match(/heatmap__grid/, response.body)

    users(:member).lesson_completions.create!(lesson: lessons(:pteep))
    get dashboard_path
    assert_match "heatmap__grid", response.body
    assert_match "heatmap__cell--l1", response.body
  end

  test "shows stage milestone chips" do
    users(:member).lesson_completions.create!(lesson: lessons(:pteep))

    sign_in_as users(:member)
    get dashboard_path
    assert_match "stage-chip", response.body
  end
end
