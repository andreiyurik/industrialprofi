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

  test "the list paginates once it overflows one page" do
    sign_in_as users(:admin)
    per = Admin::UsersController::PER_PAGE
    per.times { |i| User.create!(name: "U#{i}", email_address: "u#{i}@e.com", password: "password12") }

    get admin_users_path
    assert_response :success
    assert_select ".admin-row", per, "first page is capped at PER_PAGE"
    assert_select ".admin-pagination"

    get admin_users_path(page: 2)
    assert_response :success
    assert_select ".admin-row", minimum: 1
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

  # ── Per-profession access grants ──

  test "admin grants and revokes an editor's profession access" do
    sign_in_as users(:admin)
    editor = users(:editor)

    # Grant only the welder profession (replacing the seeded electrician/draft grants).
    patch admin_user_path(editor), params: { user: { editable_path_ids: [ paths(:welder).id, "" ] } }
    assert_redirected_to admin_users_path
    assert_equal [ paths(:welder).id ], editor.reload.editable_path_ids

    # Unticking everything clears all access (the blank value carries an empty set).
    patch admin_user_path(editor), params: { user: { editable_path_ids: [ "" ] } }
    assert_empty editor.reload.editable_path_ids
  end
end
