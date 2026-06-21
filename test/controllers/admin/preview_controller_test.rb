require "test_helper"

class Admin::PreviewControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "preview without auth redirects to sign-in" do
    sign_out
    post admin_preview_path, params: { text: "**bold**" }
    assert_redirected_to new_session_path
  end

  test "preview returns rendered HTML" do
    post admin_preview_path, params: { text: "**bold**" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json["html"], "<strong>"
  end

  test "preview handles empty text" do
    post admin_preview_path, params: { text: "" }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "", json["html"]
  end
end
