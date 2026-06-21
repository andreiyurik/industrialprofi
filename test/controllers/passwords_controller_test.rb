require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "new renders the request form" do
    get new_password_path
    assert_response :success
    assert_select "form[action=?]", passwords_path
  end

  test "create sends a reset email for a known address" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: users(:member).email_address }
    end
    assert_redirected_to new_session_path
  end

  test "create replies identically for an unknown address" do
    assert_enqueued_emails 0 do
      post passwords_path, params: { email_address: "nobody@example.com" }
    end
    assert_redirected_to new_session_path
  end

  test "edit with a valid token renders the new-password form" do
    get edit_password_path(users(:member).password_reset_token)
    assert_response :success
    assert_select "input[name=password]"
  end

  test "edit with a bogus token redirects with an alert" do
    get edit_password_path("garbage")
    assert_redirected_to new_password_path
  end

  test "update changes the password, kills old sessions and allows sign-in" do
    user = users(:member)
    user.sessions.create!(user_agent: "other device", ip_address: "10.0.0.1")
    assert_operator user.sessions.count, :>, 0

    patch password_path(user.password_reset_token),
      params: { password: "new-password-123", password_confirmation: "new-password-123" }
    assert_redirected_to new_session_path
    assert_equal 0, user.sessions.reload.count

    post session_path, params: { email_address: user.email_address, password: "new-password-123" }
    assert_redirected_to dashboard_path
  end

  test "update with mismatched confirmation re-renders" do
    patch password_path(users(:member).password_reset_token),
      params: { password: "new-password-123", password_confirmation: "different" }
    assert_response :unprocessable_entity
  end

  test "token is invalidated after the password changes" do
    user = users(:member)
    token = user.password_reset_token
    patch password_path(token),
      params: { password: "new-password-123", password_confirmation: "new-password-123" }

    get edit_password_path(token)
    assert_redirected_to new_password_path
  end
end
