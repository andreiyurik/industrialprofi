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
    paths(:electrician).verify!(users(:editor))

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

  test "an administrator without a grant on the map cannot set the mark — a grant is the expert's credential" do
    sign_in_as users(:admin)
    post admin_path_verification_path(paths(:electrician))
    assert_redirected_to path_path(paths(:electrician))
    assert_equal I18n.t("paths.maturity.verify_refused"), flash[:alert]
    assert_not paths(:electrician).reload.verified?

    # …and can, once they hold one.
    Editorship.create!(user: users(:admin), path: paths(:electrician))
    post admin_path_verification_path(paths(:electrician))
    assert paths(:electrician).reload.verified?
  end

  test "a map without the rungs beneath cannot be marked, even by its curator" do
    # The welder: no accepted edits → stage 1 even with a curator granted.
    Editorship.create!(user: users(:editor), path: paths(:welder))
    sign_in_as users(:editor)
    post admin_path_verification_path(paths(:welder))
    assert_redirected_to path_path(paths(:welder))
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
