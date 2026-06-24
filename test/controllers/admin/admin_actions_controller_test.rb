require "test_helper"

class Admin::AdminActionsControllerTest < ActionDispatch::IntegrationTest
  # ── Auth: the log is administrator-only ──

  test "index without auth redirects to sign-in" do
    get admin_log_path
    assert_redirected_to new_session_path
  end

  test "index as a member is not allowed" do
    sign_in_as users(:member)
    get admin_log_path
    assert_redirected_to root_path
  end

  test "index as an editor is not allowed" do
    sign_in_as users(:editor)
    get admin_log_path
    assert_redirected_to root_path
  end

  # ── Index ──

  test "index lists recorded actions as readable sentences" do
    AdminAction.create!(actor: users(:admin), action: "user_role_changed",
      target: users(:member), details: { subject: "Иван", from: "member", to: "editor" })

    sign_in_as users(:admin)
    get admin_log_path
    assert_response :success
    assert_match "Роль изменена", response.body
    assert_match "Иван", response.body
  end

  test "index shows an empty state when nothing is logged" do
    sign_in_as users(:admin)
    get admin_log_path
    assert_response :success
    assert_select ".admin-empty"
  end

  # ── Recording: privileged actions append a log entry ──

  test "changing a user's role records an entry" do
    sign_in_as users(:admin)
    assert_difference -> { AdminAction.count }, 1 do
      patch admin_user_path(users(:member)), params: { user: { role: "editor" } }
    end
    entry = AdminAction.ordered.first
    assert_equal "user_role_changed", entry.action
    assert_equal users(:admin), entry.actor
    assert_equal "member", entry.details["from"]
    assert_equal "editor", entry.details["to"]
  end

  test "approving a suggestion records an entry" do
    sign_in_as users(:admin)
    assert_difference -> { AdminAction.count }, 1 do
      patch approve_admin_lesson_suggestion_path(lesson_suggestions(:pending_suggestion))
    end
    assert_equal "suggestion_approved", AdminAction.ordered.first.action
  end

  test "a failed role change writes no log entry" do
    sign_in_as users(:admin)
    assert_no_difference -> { AdminAction.count } do
      patch admin_user_path(users(:member)), params: { user: { role: "superuser" } }
    end
  end
end
