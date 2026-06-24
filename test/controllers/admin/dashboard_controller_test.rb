require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  # ── Auth: the overview is admin-only ──

  test "show without auth redirects to sign-in" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "show as a member is not allowed" do
    sign_in_as users(:member)
    get admin_root_path
    assert_redirected_to root_path
  end

  test "show as an editor is not allowed" do
    sign_in_as users(:editor)
    get admin_root_path
    assert_redirected_to root_path
  end

  # ── Content ──

  test "show as admin renders the stats" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_response :success
    assert_match User.count.to_s, response.body
    assert_match users(:member).email_address, response.body  # recent signups
    assert_match I18n.t("admin.dashboard.signups_chart"), response.body
  end

  test "pending suggestions callout links to the moderation queue" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.review_now"), response.body
  end

  test "the disk-safety card renders" do
    sign_in_as users(:admin)
    get admin_root_path
    assert_match I18n.t("admin.dashboard.disk_free"), response.body
    assert_match "База данных", response.body
  end

  test "callout is hidden when the queue is empty" do
    LessonSuggestion.pending.update_all(status: "approved")
    sign_in_as users(:admin)
    get admin_root_path
    assert_no_match I18n.t("admin.dashboard.review_now"), response.body
  end
end
