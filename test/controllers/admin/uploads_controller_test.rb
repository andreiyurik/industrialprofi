require "test_helper"

class Admin::UploadsControllerTest < ActionDispatch::IntegrationTest
  def blob_params(content_type: "image/png", byte_size: 50.kilobytes)
    { blob: { filename: "diagram.png", byte_size: byte_size,
              checksum: "0123456789abcdef0123456789abcdef", content_type: content_type } }
  end

  test "without auth it redirects to sign-in" do
    post admin_uploads_path, params: blob_params
    assert_redirected_to new_session_path
  end

  test "a member cannot upload" do
    sign_in_as users(:member)
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_uploads_path, params: blob_params
    end
    assert_redirected_to root_path
  end

  test "an editor uploads a small image" do
    sign_in_as users(:editor)
    assert_difference -> { ActiveStorage::Blob.count }, 1 do
      post admin_uploads_path, params: blob_params
    end
    assert_response :success
    assert JSON.parse(response.body)["signed_id"].present?
  end

  test "an oversized image is refused" do
    sign_in_as users(:editor)
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_uploads_path, params: blob_params(byte_size: 15.megabytes)
    end
    assert_response :unprocessable_entity
  end

  test "a non-image file is refused" do
    sign_in_as users(:editor)
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_uploads_path, params: blob_params(content_type: "application/pdf")
    end
    assert_response :unprocessable_entity
  end

  test "an SVG is refused (XSS surface; diagrams stay curated)" do
    sign_in_as users(:editor)
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_uploads_path, params: blob_params(content_type: "image/svg+xml")
    end
    assert_response :unprocessable_entity
  end
end
