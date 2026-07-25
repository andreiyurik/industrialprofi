require "test_helper"

class Admin::IllustrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  # Auth

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_illustrations_path
    assert_redirected_to new_session_path
  end

  test "index is closed to a plain member" do
    sign_out
    sign_in_as users(:member)
    get admin_illustrations_path
    assert_response :redirect
  end

  test "an editor may see the backlog" do
    sign_out
    sign_in_as users(:editor)
    get admin_illustrations_path
    assert_response :success
  end

  # Index

  test "lists a lesson's placeholder brief and links into its editor" do
    lesson = lessons(:pteep)
    lesson.update!(body: "Текст.\n\n![Схема допуска — кто кого допускает](TODO-elektrik-dopusk.png)\n\nЕщё текст.")

    get admin_illustrations_path
    assert_response :success
    assert_match "Схема допуска", response.body
    assert_match lesson.title, response.body
    assert_select "a[href=?]", edit_admin_lesson_path(lesson)
  end

  test "counts a placeholder inside the task section too" do
    lessons(:pteep).update!(task: "![Разметка стенда](placeholder: фото стенда)")

    get admin_illustrations_path
    assert_response :success
    assert_match "Разметка стенда", response.body
  end

  test "a real image is not treated as a placeholder" do
    lessons(:pteep).update!(body: "![Готовая схема](/rails/active_storage/blobs/redirect/abc/foto.png)")

    get admin_illustrations_path
    assert_response :success
    assert_match I18n.t("admin.illustrations.empty"), response.body
  end

  test "shows the empty state when nothing is pending" do
    get admin_illustrations_path
    assert_response :success
    assert_match I18n.t("admin.illustrations.empty"), response.body
  end
end
