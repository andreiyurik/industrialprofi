require "test_helper"

class Admin::LessonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # ── Auth ──

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_lessons_path
    assert_redirected_to new_session_path
  end

  test "index as a regular member is not allowed" do
    sign_out
    sign_in_as users(:member)
    get admin_lessons_path
    assert_redirected_to root_path
  end

  test "index as an editor is allowed" do
    sign_out
    sign_in_as users(:editor)
    get admin_lessons_path
    assert_response :success
  end

  test "edit without auth redirects to sign-in" do
    sign_out
    get edit_admin_lesson_path(lessons(:pteep))
    assert_redirected_to new_session_path
  end

  # ── Index: profession picker → drill-in ──

  test "the bare index is a profession picker, not a dump of every lesson" do
    get admin_lessons_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
    assert_no_match(/#{lessons(:pteep).title}/, response.body)
  end

  test "drilling into a profession lists its lessons grouped by course" do
    get admin_lessons_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match lessons(:pteep).title, response.body
    assert_match courses(:el_basics).title, response.body
  end

  test "an editor cannot drill into a profession they weren't granted" do
    sign_out
    sign_in_as users(:editor)
    get admin_lessons_path(path: paths(:welder).slug)
    assert_response :not_found
  end

  test "the drill-in paginates a large profession" do
    per = Admin::LessonsController::PER_PAGE
    course = courses(:el_basics)
    base = paths(:electrician).lessons.maximum(:position) || 0
    per.times do |i|
      course.lessons.create!(title: "Урок #{i}", slug: "pg-lesson-#{i}", stage: "Раздел",
                             kind: "lesson", position: base + i + 1)
    end

    get admin_lessons_path(path: paths(:electrician).slug)
    assert_response :success
    assert_select ".admin-pagination"

    get admin_lessons_path(path: paths(:electrician).slug, page: 2)
    assert_response :success
    assert_select ".admin-row", minimum: 1
  end

  # ── Edit ──

  test "edit with auth returns success" do
    get edit_admin_lesson_path(lessons(:pteep))
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "edit shows rich text editor" do
    get edit_admin_lesson_path(lessons(:pteep))
    assert_select "[name='lesson[rich_body]']"
  end

  # ── Update ──

  test "update with valid data redirects" do
    patch admin_lesson_path(lessons(:pteep)),
      params: { lesson: { body: "Updated body" } }
    assert_redirected_to edit_admin_lesson_path(lessons(:pteep))
    assert_equal "Updated body", lessons(:pteep).reload.body
  end

  test "update with invalid data re-renders edit" do
    patch admin_lesson_path(lessons(:pteep)),
      params: { lesson: { title: "" } }
    assert_response :unprocessable_entity
  end

  # ── Resource editor ──

  test "edit renders the resource editor with a row per existing resource" do
    get edit_admin_lesson_path(lessons(:pteep))
    assert_response :success
    assert_select ".resource-editor"
    assert_select ".resource-editor__list .resource-row", lessons(:pteep).resources.count
    assert_select "input[value=?]", resources(:pteep_doc).title
  end

  test "update can add a resource and the lesson takes human ownership" do
    lessons(:pteep).update_column(:origin, "seed")

    assert_difference -> { lessons(:pteep).resources.count }, 1 do
      patch admin_lesson_path(lessons(:pteep)), params: { lesson: {
        resources_attributes: {
          "0" => existing_attrs(resources(:pteep_doc), position: 0),
          "1700000001" => { title: "ГОСТ 12.1.030-81", url: "https://example.com/gost",
                            kind: "document", required: "1", position: 1 }
        }
      } }
    end

    assert_redirected_to edit_admin_lesson_path(lessons(:pteep))
    assert_equal "human", lessons(:pteep).reload.origin
    added = lessons(:pteep).resources.find_by(title: "ГОСТ 12.1.030-81")
    assert_equal "https://example.com/gost", added.url
    assert_nil added.country_code, "editor-created resources are universal (no country) by default"
  end

  test "update can remove a resource via _destroy" do
    assert_difference -> { lessons(:pteep).resources.count }, -1 do
      patch admin_lesson_path(lessons(:pteep)), params: { lesson: {
        resources_attributes: { "0" => { id: resources(:pteep_doc).id, _destroy: "1" } }
      } }
    end
  end

  test "an empty added row is ignored, not a validation error" do
    assert_no_difference -> { lessons(:pteep).resources.count } do
      patch admin_lesson_path(lessons(:pteep)), params: { lesson: {
        resources_attributes: { "1700000002" => { title: "", url: "", kind: "document" } }
      } }
    end
    assert_redirected_to edit_admin_lesson_path(lessons(:pteep))
  end

  test "an invalid resource re-renders edit" do
    patch admin_lesson_path(lessons(:pteep)), params: { lesson: {
      resources_attributes: { "1700000003" => { title: "x", url: "not-a-url", kind: "document" } }
    } }
    assert_response :unprocessable_entity
  end

  # ── Per-profession access (editorships) ──

  test "an editor can edit a lesson in a granted profession" do
    sign_out
    sign_in_as users(:editor)
    get edit_admin_lesson_path(lessons(:pteep)) # electrician — granted
    assert_response :success
  end

  test "an editor cannot edit a lesson in a profession they weren't granted" do
    sign_out
    sign_in_as users(:editor)
    get edit_admin_lesson_path(lessons(:svarka_intro)) # welder — not granted
    assert_redirected_to admin_lessons_path
  end

  test "an editor cannot update a lesson in an ungranted profession" do
    sign_out
    sign_in_as users(:editor)
    patch admin_lesson_path(lessons(:svarka_intro)), params: { lesson: { body: "Взлом" } }
    assert_redirected_to admin_lessons_path
    assert_not_equal "Взлом", lessons(:svarka_intro).reload.body
  end

  test "an editor cannot create a lesson under an ungranted profession's course" do
    sign_out
    sign_in_as users(:editor)
    assert_no_difference -> { Lesson.count } do
      post admin_lessons_path, params: { lesson: {
        course_id: courses(:welding_basics).id, title: "Чужой урок", kind: "lesson"
      } }
    end
    assert_redirected_to admin_lessons_path
  end

  # ── Create ──

  test "new lesson form renders" do
    get new_admin_lesson_path
    assert_response :success
  end

  test "create builds a stub, appends position, and redirects to the full edit" do
    assert_difference -> { Lesson.count }, 1 do
      post admin_lessons_path, params: { lesson: {
        course_id: courses(:el_basics).id, stage: "Раздел X", title: "Новый Урок X", kind: "lesson"
      } }
    end
    lesson = Lesson.find_by!(title: "Новый Урок X")
    assert_redirected_to edit_admin_lesson_path(lesson)
    assert_equal courses(:el_basics), lesson.course
    assert_equal paths(:electrician), lesson.path
    assert_equal "human", lesson.origin
    assert_equal "Раздел X", lesson.stage
    assert_equal "novyy-urok-x", lesson.slug
    assert_equal paths(:electrician).lessons.maximum(:position), lesson.position
  end

  test "a new practice lesson gets a default difficulty" do
    post admin_lessons_path, params: { lesson: {
      course_id: courses(:el_basics).id, title: "Практика X", kind: "practice"
    } }
    assert_equal "beginner", Lesson.find_by!(title: "Практика X").difficulty
  end

  test "create without a course re-renders" do
    post admin_lessons_path, params: { lesson: { title: "Сирота", kind: "lesson" } }
    assert_response :unprocessable_entity
  end

  private
    def existing_attrs(resource, position:)
      { id: resource.id, title: resource.title, url: resource.url,
        kind: resource.kind, required: resource.required ? "1" : "0", position: position }
    end
end
