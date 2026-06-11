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
end
