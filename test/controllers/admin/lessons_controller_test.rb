require "test_helper"

class Admin::LessonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @credentials = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", "secret") }
  end

  # ── Auth ──

  test "index without auth returns 401" do
    get admin_lessons_path
    assert_response :unauthorized
  end

  test "edit without auth returns 401" do
    get edit_admin_lesson_path(lessons(:pteep))
    assert_response :unauthorized
  end

  # ── Index ──

  test "index with auth returns success" do
    get admin_lessons_path, headers: @credentials
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "index groups lessons by path" do
    get admin_lessons_path, headers: @credentials
    assert_match paths(:electrician).title, response.body
  end

  # ── Edit ──

  test "edit with auth returns success" do
    get edit_admin_lesson_path(lessons(:pteep)), headers: @credentials
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "edit shows rich text editor" do
    get edit_admin_lesson_path(lessons(:pteep)), headers: @credentials
    assert_select "[name='lesson[rich_body]']"
  end

  # ── Update ──

  test "update with valid data redirects" do
    patch admin_lesson_path(lessons(:pteep)),
      params: { lesson: { body: "Updated body" } },
      headers: @credentials
    assert_redirected_to edit_admin_lesson_path(lessons(:pteep))
    assert_equal "Updated body", lessons(:pteep).reload.body
  end

  test "update with invalid data re-renders edit" do
    patch admin_lesson_path(lessons(:pteep)),
      params: { lesson: { title: "" } },
      headers: @credentials
    assert_response :unprocessable_entity
  end
end
