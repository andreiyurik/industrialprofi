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

  # ── Index ──

  test "index with auth returns success" do
    get admin_lessons_path
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "index groups lessons by path" do
    get admin_lessons_path
    assert_match paths(:electrician).title, response.body
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

  private
    def existing_attrs(resource, position:)
      { id: resource.id, title: resource.title, url: resource.url,
        kind: resource.kind, required: resource.required ? "1" : "0", position: position }
    end
end
