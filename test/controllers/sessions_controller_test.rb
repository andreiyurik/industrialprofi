require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the sign-in form" do
    get new_session_path
    assert_response :success
    assert_select "form[action=?]", session_path
  end

  test "create with valid credentials signs in and goes to dashboard" do
    post session_path, params: { email_address: users(:member).email_address, password: "password" }
    assert_redirected_to dashboard_path

    follow_redirect!
    assert_response :success
    assert_match users(:member).name, response.body
  end

  test "create with wrong password re-renders with an error" do
    post session_path, params: { email_address: users(:member).email_address, password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "create returns to the page the visitor came from" do
    get dashboard_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:member).email_address, password: "password" }
    assert_redirected_to dashboard_url
  end

  test "destroy signs out" do
    sign_in_as users(:member)
    delete session_path
    assert_redirected_to root_path

    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "signed-in user visiting sign-in is sent to the dashboard" do
    sign_in_as users(:member)
    get new_session_path
    assert_redirected_to dashboard_path
  end
end
