require "test_helper"

class Admin::Paths::VerificationsControllerTest < ActionDispatch::IntegrationTest
  test "a granted editor sets the expert mark and it is logged" do
    sign_in_as users(:editor)
    assert_difference -> { AdminAction.where(action: "path_verified").count } do
      post admin_path_verification_path(paths(:electrician))
    end
    assert_redirected_to path_path(paths(:electrician))
    assert paths(:electrician).reload.verified?
    assert_equal users(:editor), paths(:electrician).verified_by
  end

  test "clearing the mark is logged too" do
    paths(:electrician).verify!(users(:admin))

    sign_in_as users(:editor)
    assert_difference -> { AdminAction.where(action: "path_unverified").count } do
      delete admin_path_verification_path(paths(:electrician))
    end
    assert_not paths(:electrician).reload.verified?
  end

  test "an editor cannot verify a map they were not granted" do
    sign_in_as users(:editor)
    post admin_path_verification_path(paths(:welder))
    assert_response :not_found
    assert_not paths(:welder).reload.verified?
  end

  test "a member cannot verify" do
    sign_in_as users(:member)
    post admin_path_verification_path(paths(:electrician))
    assert_redirected_to root_path
    assert_not paths(:electrician).reload.verified?
  end

  test "verification requires sign-in" do
    post admin_path_verification_path(paths(:electrician))
    assert_redirected_to new_session_path
  end
end
