require "test_helper"

class Admin::PreviewControllerTest < ActionDispatch::IntegrationTest
  setup do
    @credentials = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") }
  end

  test "preview without auth returns 401" do
    post admin_preview_path, params: { text: "**bold**" }
    assert_response :unauthorized
  end

  test "preview returns rendered HTML" do
    post admin_preview_path,
      params: { text: "**bold**" },
      headers: @credentials,
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json["html"], "<strong>"
  end

  test "preview handles empty text" do
    post admin_preview_path,
      params: { text: "" },
      headers: @credentials,
      as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "", json["html"]
  end
end
