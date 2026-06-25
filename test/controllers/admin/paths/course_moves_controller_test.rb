require "test_helper"

class Admin::Paths::CourseMovesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "create renumbers courses and the global lesson positions follow" do
    post admin_path_course_moves_path(paths(:electrician)), params: {
      course_ids: [ courses(:el_pue).id, courses(:el_basics).id, courses(:el_relay_soon).id ]
    }
    assert_response :no_content
    assert_equal 1, courses(:el_pue).reload.position
    assert_equal 2, courses(:el_basics).reload.position
    # el_pue is now first, so its lessons take the leading global positions and
    # the continuous prev/next flow stays intact.
    assert_equal 1, lessons(:zazemlenie).reload.position
    assert_equal 3, lessons(:pteep).reload.position
  end

  test "an editor cannot move courses in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    post admin_path_course_moves_path(paths(:welder)), params: {
      course_ids: [ courses(:welding_basics).id ]
    }
    assert_response :not_found
  end
end
