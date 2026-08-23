require "test_helper"

class Admin::PhotosControllerTest < ActionDispatch::IntegrationTest
  test "an administrator removes a curator's photo and the act is logged" do
    users(:editor).update_photo(fixture_file_upload("cover.png", "image/png"))
    sign_in_as users(:admin)

    assert_difference -> { AdminAction.where(action: "user_photo_removed").count }, 1 do
      delete admin_user_photo_url(users(:editor))
    end
    assert_redirected_to admin_user_url(users(:editor))
    assert_not users(:editor).reload.photo.attached?
  end

  test "editors cannot remove photos" do
    sign_in_as users(:editor)
    delete admin_user_photo_url(users(:member))
    assert_redirected_to root_path
  end
end
