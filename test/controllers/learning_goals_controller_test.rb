require "test_helper"

class LearningGoalsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get edit_learning_goal_path
    assert_redirected_to new_session_path
  end

  test "edit renders the inline form" do
    sign_in_as users(:member)
    get edit_learning_goal_path
    assert_response :success
    assert_match "learning_goal", response.body
  end

  test "saves the goal and returns to the dashboard" do
    sign_in_as users(:member)
    patch learning_goal_path, params: { user: { learning_goal: "Стать электромонтажником за год" } }
    assert_redirected_to dashboard_path
    assert_equal "Стать электромонтажником за год", users(:member).reload.learning_goal
  end

  test "blank goal clears it" do
    users(:member).update!(learning_goal: "Старая цель")
    sign_in_as users(:member)
    patch learning_goal_path, params: { user: { learning_goal: "   " } }
    assert_nil users(:member).reload.learning_goal
  end

  test "rejects an overlong goal" do
    sign_in_as users(:member)
    patch learning_goal_path, params: { user: { learning_goal: "ц" * 201 } }
    assert_response :unprocessable_entity
    assert_nil users(:member).reload.learning_goal
  end

  test "dashboard shows the saved goal" do
    users(:member).update!(learning_goal: "Моя большая цель")
    sign_in_as users(:member)
    get dashboard_path
    assert_match "Моя большая цель", response.body
  end

  test "dashboard prompts when no goal is set" do
    sign_in_as users(:member)
    get dashboard_path
    assert_match I18n.t("dashboard.goal.prompt"), response.body
  end
end
