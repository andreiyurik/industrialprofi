require "test_helper"

class Admin::Paths::LessonMovesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "create renumbers lesson positions within a profession" do
    post admin_path_lesson_moves_path(paths(:electrician)), params: {
      lessons: [
        { id: lessons(:gruppy_dopuska).id, course_id: courses(:el_basics).id, stage: "Электробезопасность и допуски" },
        { id: lessons(:pteep).id, course_id: courses(:el_basics).id, stage: "Электробезопасность и допуски" },
        { id: lessons(:zazemlenie).id, course_id: courses(:el_pue).id, stage: "Правила устройства электроустановок" },
        { id: lessons(:praktika_shchitok).id, course_id: courses(:el_pue).id, stage: "Правила устройства электроустановок" }
      ]
    }
    assert_response :no_content
    assert_equal 1, lessons(:gruppy_dopuska).reload.position
    assert_equal 2, lessons(:pteep).reload.position
  end

  test "create can move a lesson into another course, fixing both counter caches" do
    assert_difference -> { courses(:el_pue).reload.lessons_count }, +1 do
      assert_difference -> { courses(:el_basics).reload.lessons_count }, -1 do
        post admin_path_lesson_moves_path(paths(:electrician)), params: {
          lessons: [
            { id: lessons(:gruppy_dopuska).id, course_id: courses(:el_basics).id, stage: "" },
            { id: lessons(:zazemlenie).id, course_id: courses(:el_pue).id, stage: "" },
            { id: lessons(:pteep).id, course_id: courses(:el_pue).id, stage: "" },
            { id: lessons(:praktika_shchitok).id, course_id: courses(:el_pue).id, stage: "" }
          ]
        }
      end
    end
    assert_response :no_content
    pteep = lessons(:pteep).reload
    assert_equal courses(:el_pue), pteep.course
    assert_equal paths(:electrician), pteep.path, "the denormalized path_id stays in sync"
    assert_equal 3, pteep.position
  end

  # A whole stage moved as a block is just a payload where its lessons travel
  # together, keeping their shared stage, into another course (Phase 2 builder).
  test "create can move a whole stage (its lessons together) into another course" do
    assert_difference -> { courses(:el_pue).reload.lessons_count }, +2 do
      post admin_path_lesson_moves_path(paths(:electrician)), params: {
        lessons: [
          { id: lessons(:zazemlenie).id, course_id: courses(:el_pue).id, stage: "Правила устройства электроустановок" },
          { id: lessons(:praktika_shchitok).id, course_id: courses(:el_pue).id, stage: "Правила устройства электроустановок" },
          { id: lessons(:pteep).id, course_id: courses(:el_pue).id, stage: "Электробезопасность и допуски" },
          { id: lessons(:gruppy_dopuska).id, course_id: courses(:el_pue).id, stage: "Электробезопасность и допуски" }
        ]
      }
    end
    assert_response :no_content
    [ lessons(:pteep), lessons(:gruppy_dopuska) ].each(&:reload)
    assert_equal courses(:el_pue), lessons(:pteep).course
    assert_equal courses(:el_pue), lessons(:gruppy_dopuska).course
    assert_equal "Электробезопасность и допуски", lessons(:pteep).stage, "the section label travels with the block"
    assert_equal [ 3, 4 ], [ lessons(:pteep).position, lessons(:gruppy_dopuska).position ]
  end

  test "an editor cannot move lessons in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    post admin_path_lesson_moves_path(paths(:welder)), params: {
      lessons: [ { id: lessons(:svarka_intro).id, course_id: courses(:welding_basics).id, stage: "" } ]
    }
    assert_response :not_found
    assert_equal 1, lessons(:svarka_intro).reload.position
  end

  test "without auth it redirects to sign-in" do
    sign_out
    post admin_path_lesson_moves_path(paths(:electrician)), params: { lessons: [] }
    assert_redirected_to new_session_path
  end
end
