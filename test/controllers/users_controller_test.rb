require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new renders the sign-up form" do
    get new_user_path
    assert_response :success
    assert_select "form[action=?]", users_path
  end

  test "create registers, signs in and goes to dashboard" do
    assert_difference -> { User.count }, 1 do
      post users_path, params: { user: {
        name: "Новый",
        email_address: "new@example.com",
        password: "password123",
        password_confirmation: "password123"
      } }
    end
    assert_redirected_to dashboard_path

    follow_redirect!
    assert_response :success
  end

  test "create with invalid data re-renders the form" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: {
        name: "",
        email_address: "bad",
        password: "short",
        password_confirmation: "short"
      } }
    end
    assert_response :unprocessable_entity
  end
end
