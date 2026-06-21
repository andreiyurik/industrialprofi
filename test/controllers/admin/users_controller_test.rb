require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  # ── Auth: users management is admin-only, NOT editor ──

  test "index without auth redirects to sign-in" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "index as a member is not allowed" do
    sign_in_as users(:member)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "index as an editor is not allowed" do
    sign_in_as users(:editor)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "update as an editor is not allowed" do
    sign_in_as users(:editor)
    patch admin_user_path(users(:member)), params: { user: { role: "editor" } }
    assert_redirected_to root_path
    assert users(:member).reload.member?
  end

  # ── Index ──

  test "index as admin lists users" do
    sign_in_as users(:admin)
    get admin_users_path
    assert_response :success
    assert_match users(:member).email_address, response.body
    assert_match users(:editor).email_address, response.body
  end

  test "index filters by search query" do
    sign_in_as users(:admin)
    get admin_users_path, params: { q: users(:editor).email_address }
    assert_response :success
    assert_match users(:editor).email_address, response.body
    assert_no_match users(:member).email_address, response.body
  end

  # ── Role assignment ──

  test "admin promotes a member to editor" do
    sign_in_as users(:admin)
    patch admin_user_path(users(:member)), params: { user: { role: "editor" } }
    assert_redirected_to admin_users_path
    assert users(:member).reload.editor?
  end

  test "admin demotes an editor to member" do
    sign_in_as users(:admin)
    patch admin_user_path(users(:editor)), params: { user: { role: "member" } }
    assert users(:editor).reload.member?
  end

  test "admin cannot change own role" do
    sign_in_as users(:admin)
    patch admin_user_path(users(:admin)), params: { user: { role: "member" } }
    assert_redirected_to admin_users_path
    assert users(:admin).reload.administrator?
  end

  test "unknown role is rejected" do
    sign_in_as users(:admin)
    patch admin_user_path(users(:member)), params: { user: { role: "superuser" } }
    assert_response :unprocessable_entity
    assert users(:member).reload.member?
  end
end
