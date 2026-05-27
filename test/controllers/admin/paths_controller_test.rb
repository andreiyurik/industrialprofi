require "test_helper"

class Admin::PathsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @credentials = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") }
  end

  test "index without auth returns 401" do
    get admin_paths_path
    assert_response :unauthorized
  end

  test "index with auth returns success" do
    get admin_paths_path, headers: @credentials
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "edit with auth returns success" do
    get edit_admin_path_path(paths(:electrician)), headers: @credentials
    assert_response :success
  end

  test "update with valid data redirects" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { description: "New description" } },
      headers: @credentials
    assert_redirected_to edit_admin_path_path(paths(:electrician))
    assert_equal "New description", paths(:electrician).reload.description
  end

  test "update with invalid data re-renders edit" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { title: "" } },
      headers: @credentials
    assert_response :unprocessable_entity
  end
end
