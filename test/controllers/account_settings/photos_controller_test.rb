require "test_helper"

class AccountSettings::PhotosControllerTest < ActionDispatch::IntegrationTest
  test "a curator uploads a photo, sees it on the map, and removes it" do
    sign_in_as users(:editor)
    post account_photo_url, params: { photo: fixture_file_upload("cover.png", "image/png") }
    assert_redirected_to account_url
    assert users(:editor).reload.photo.attached?

    get path_url(paths(:electrician))
    assert_select ".hub-people__faces img.avatar--photo"

    delete account_photo_url
    assert_redirected_to account_url
    assert_not users(:editor).reload.photo.attached?
  end

  test "a broken upload is refused with a message, nothing attached" do
    sign_in_as users(:editor)
    post account_photo_url, params: { photo: fixture_file_upload("cover.png", "text/plain") }
    assert_redirected_to account_url
    assert_equal I18n.t("account.photo_invalid"), flash[:alert]
    assert_not users(:editor).reload.photo.attached?
  end

  test "members have no photo to manage" do
    sign_in_as users(:member)
    post account_photo_url, params: { photo: fixture_file_upload("cover.png", "image/png") }
    assert_response :forbidden

    get account_url
    assert_select ".photo-actions", false
  end
end
