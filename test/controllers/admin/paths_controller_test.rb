require "test_helper"

class Admin::PathsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_paths_path
    assert_redirected_to new_session_path
  end

  test "index with auth returns success" do
    get admin_paths_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "edit with auth returns success" do
    get edit_admin_path_path(paths(:electrician))
    assert_response :success
  end

  test "update with valid data redirects" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { description: "New description" } }
    assert_redirected_to edit_admin_path_path(paths(:electrician))
    assert_equal "New description", paths(:electrician).reload.description
  end

  test "update with invalid data re-renders edit" do
    patch admin_path_path(paths(:electrician)),
      params: { path: { title: "" } }
    assert_response :unprocessable_entity
  end
end
