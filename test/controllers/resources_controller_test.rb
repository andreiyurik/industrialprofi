require "test_helper"

class ResourcesControllerTest < ActionDispatch::IntegrationTest
  test "the hub is public and lists professions that have documents" do
    get resources_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "a profession's library 301s to its hub reference shelf" do
    get resources_path(path: paths(:electrician).slug)
    assert_redirected_to path_library_path(paths(:electrician))
    assert_response :moved_permanently
  end

  test "an unpublished profession's library is not found" do
    get resources_path(path: paths(:draft_path).slug)
    assert_response :not_found
  end
end
