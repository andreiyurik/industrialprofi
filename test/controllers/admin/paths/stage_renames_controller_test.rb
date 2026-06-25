require "test_helper"

class Admin::Paths::StageRenamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "update renames a section across every lesson in the course that carries it" do
    from = lessons(:pteep).stage
    assert_equal from, lessons(:gruppy_dopuska).stage, "fixtures share the section"

    patch admin_path_stage_rename_path(paths(:electrician)), params: {
      course_id: courses(:el_basics).id, from: from, value: "Охрана труда и допуски"
    }
    assert_response :no_content
    assert_equal "Охрана труда и допуски", lessons(:pteep).reload.stage
    assert_equal "Охрана труда и допуски", lessons(:gruppy_dopuska).reload.stage
    assert_equal "human", lessons(:pteep).reload.origin, "a human rename takes ownership"
  end

  test "a blank new name is rejected" do
    patch admin_path_stage_rename_path(paths(:electrician)), params: {
      course_id: courses(:el_basics).id, from: lessons(:pteep).stage, value: " "
    }
    assert_response :unprocessable_entity
  end

  test "an editor cannot rename a section in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    patch admin_path_stage_rename_path(paths(:welder)), params: {
      course_id: courses(:welding_basics).id, from: lessons(:svarka_intro).stage, value: "Взлом"
    }
    assert_response :not_found
  end
end
