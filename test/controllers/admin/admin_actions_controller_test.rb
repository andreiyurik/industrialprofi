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

  # ── Filters ──

  test "filters the log by action category" do
    admin = users(:admin)
    AdminAction.create!(actor: admin, action: "user_suspended", details: { subject: "Спамер" })
    AdminAction.create!(actor: admin, action: "suggestion_approved", details: { lesson: "Урок", section: "body" })

    sign_in_as admin
    get admin_log_path(type: "bans")
    assert_response :success
    assert_match "Спамер", response.body
    assert_no_match(/Правка одобрена/, response.body)
  end

  test "filters the log by actor" do
    a1, a2 = users(:admin), users(:editor)
    AdminAction.create!(actor: a1, action: "user_suspended", details: { subject: "Кейс-A1" })
    AdminAction.create!(actor: a2, action: "lesson_rolled_back", details: { lesson: "Кейс-A2", version: 2 })

    sign_in_as a1
    get admin_log_path(actor: a2.id)
    assert_response :success
    assert_match "Кейс-A2", response.body
    assert_no_match(/Кейс-A1/, response.body)
  end

  test "empty filtered result offers a reset" do
    sign_in_as users(:admin)
    get admin_log_path(type: "bans")
    assert_response :success
    assert_select ".admin-empty"
    assert_match I18n.t("admin.log.reset"), response.body
  end

  # ── Keyset pagination ──

  test "pages newest-first by cursor, no offset or page params" do
    admin = users(:admin)
    per = Admin::AdminActionsController::PER_PAGE
    (per + 5).times do |i|
      AdminAction.create!(actor: admin, action: "user_role_changed",
        details: { subject: "U#{i}", from: "member", to: "editor" })
    end

    sign_in_as admin
    get admin_log_path
    assert_response :success
    assert_select ".admin-list .admin-row", per                    # first page capped
    assert_select "nav.admin-pagination a[href*=?]", "before="      # cursor, not ?page=

    # Follow the older cursor: the oldest entry (U0) lands on the next page.
    oldest_on_first_page = AdminAction.order(id: :desc).offset(per - 1).first
    get admin_log_path(before: oldest_on_first_page.id)
    assert_response :success
    assert_match(/U0 —/, response.body)
    assert_no_match(/U#{per + 4} —/, response.body)                 # newest is not here
  end
end
