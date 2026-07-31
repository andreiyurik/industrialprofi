require "test_helper"

class Admin::Paths::ExportsControllerTest < ActionDispatch::IntegrationTest
  test "a granted editor downloads the profession as a pack the importer accepts" do
    sign_in_as users(:editor)
    get admin_path_export_path(paths(:electrician))

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_includes response.headers["Content-Disposition"], "#{paths(:electrician).slug}.zip"

    pack = CurriculumPack.parse(StringIO.new(response.body))
    assert pack.valid?, "exported zip should round-trip through CurriculumPack: #{pack.errors}"
    assert_includes pack.to_yaml, paths(:electrician).title
  end

  test "an editor cannot export a map they were not granted" do
    sign_in_as users(:editor)
    get admin_path_export_path(paths(:welder))
    assert_response :not_found
  end

  test "a member cannot export" do
    sign_in_as users(:member)
    get admin_path_export_path(paths(:electrician))
    assert_redirected_to root_path
  end

  test "export requires sign-in" do
    get admin_path_export_path(paths(:electrician))
    assert_redirected_to new_session_path
  end
end
