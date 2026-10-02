require "test_helper"

class Admin::NavTest < ActionDispatch::IntegrationTest
  test "administrators get every section and a count of new users" do
    sign_in_as users(:admin)
    get admin_paths_path

    assert_select ".admin-nav a[aria-current=page]", text: I18n.t("admin.manage_program")
    assert_select ".admin-nav a[href=?]", admin_users_path do
      assert_select ".admin-nav__count--info", text: User.where(created_at: 7.days.ago..).count.to_s
    end
    assert_select ".admin-nav a[href=?]", admin_log_path
  end

  test "editors see only their content sections" do
    sign_in_as users(:editor)
    get admin_paths_path

    assert_select ".admin-nav a[href=?]", admin_lesson_suggestions_path
    assert_select ".admin-nav a[href=?]", admin_root_path, count: 0
    assert_select ".admin-nav a[href=?]", admin_users_path, count: 0
  end

  test "an editor of one profession sees it by name in place of the program" do
    editorships(:editor_draft).destroy
    sign_in_as users(:editor)
    get admin_lesson_suggestions_path

    assert_select ".admin-nav a[href=?]", admin_path_path(paths(:electrician)), text: paths(:electrician).title
  end

  test "a profession page shows its health" do
    sign_in_as users(:editor)
    get admin_path_path(paths(:electrician))

    assert_select ".admin-group__title", text: I18n.t("admin.health.title")
  end
end
