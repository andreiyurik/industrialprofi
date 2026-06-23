require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "the hub is public and lists professions that have documents" do
    get resources_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "a profession's full library renders, grouped by type" do
    get resources_path(path: paths(:electrician).slug)
    assert_response :success
    assert_select ".library-group"
  end

  test "an unpublished profession's library is not found" do
    get resources_path(path: paths(:draft_path).slug)
    assert_response :not_found
  end
end
