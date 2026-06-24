require "test_helper"

class Admin::SuspensionsControllerTest < ActionDispatch::IntegrationTest
  # ── Auth: suspending is administrator-only ──

  test "create without auth redirects to sign-in" do
    post admin_user_suspension_path(users(:member))
    assert_redirected_to new_session_path
    assert_not users(:member).reload.suspended?
  end

  test "create as an editor is not allowed" do
    sign_in_as users(:editor)
    post admin_user_suspension_path(users(:member))
    assert_redirected_to root_path
    assert_not users(:member).reload.suspended?
  end

  # ── Suspend / reinstate ──

  test "admin suspends a member, revoking sessions and logging it" do
    member = users(:member)
    member.sessions.create!

    sign_in_as users(:admin)
    assert_difference -> { AdminAction.where(action: "user_suspended").count }, 1 do
      post admin_user_suspension_path(member)
    end
    assert_redirected_to admin_users_path
    assert member.reload.suspended?
    assert_equal 0, member.sessions.count
  end

  test "admin reinstates a suspended member" do
    member = users(:member)
    member.suspend!

    sign_in_as users(:admin)
    assert_difference -> { AdminAction.where(action: "user_reinstated").count }, 1 do
      delete admin_user_suspension_path(member)
    end
    assert_not member.reload.suspended?
  end

  test "admin cannot suspend themselves" do
    sign_in_as users(:admin)
    post admin_user_suspension_path(users(:admin))
    assert_redirected_to admin_users_path
    assert_not users(:admin).reload.suspended?
  end

  # ── Login gate ──

  test "a suspended user cannot sign in" do
    member = users(:member)
    member.suspend!

    post session_path, params: { email_address: member.email_address, password: "password" }
    assert_response :unprocessable_entity
    assert_nil cookies[:session_token].presence
  end

  test "a reinstated user can sign in again" do
    member = users(:member)
    member.suspend!
    member.reinstate!

    post session_path, params: { email_address: member.email_address, password: "password" }
    assert_redirected_to dashboard_path
  end
end
