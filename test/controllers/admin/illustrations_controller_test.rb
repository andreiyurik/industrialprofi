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

  test "an editor with several professions sees the landing list" do
    sign_out
    sign_in_as users(:editor)
    get admin_illustrations_path
    assert_response :success
    assert_match paths(:electrician).title, response.body
  end

  test "an editor trusted with exactly one profession lands straight in it" do
    editorships(:editor_draft).destroy
    sign_out
    sign_in_as users(:editor)

    get admin_illustrations_path
    assert_redirected_to admin_illustrations_path(path: paths(:electrician).slug)
  end

  # Landing: professions with health counts, no thumbnails

  test "landing lists professions with per-profession counts" do
    lessons(:pteep).update!(body: "![Схема](TODO-shema.png)")

    get admin_illustrations_path
    assert_response :success
    assert_select "a[href=?]", admin_illustrations_path(path: paths(:electrician).slug)
    assert_match I18n.t("admin.illustrations.briefs_count", count: 1), response.body
    assert_select ".admin-list img", 0 # numbers only — the landing never loads images
  end

  # Per-profession center

  test "shows a lesson's placeholder brief and links into its editor" do
    lesson = lessons(:pteep)
    lesson.update!(body: "Текст.\n\n![Схема допуска — кто кого допускает](TODO-elektrik-dopusk.png)\n\nЕщё текст.")

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match "Схема допуска", response.body
    assert_match lesson.title, response.body
    assert_select "a[href=?]", edit_admin_lesson_path(lesson)
  end

  test "counts a placeholder inside the task section too" do
    lessons(:pteep).update!(task: "![Разметка стенда](placeholder: фото стенда)")

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match "Разметка стенда", response.body
  end

  test "a real image shows in the gallery, not among the briefs" do
    lessons(:pteep).update!(body: "![Готовая схема](/icon.png)")

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match I18n.t("admin.illustrations.pending_empty"), response.body
    assert_select "img.illustration-card__thumb[src=?]", "/icon.png"
    assert_match "Готовая схема", response.body
  end

  test "a reference to a missing local file is flagged as broken" do
    lessons(:pteep).update!(body: "![Пропавшая схема](/lesson-images/net-takogo.svg)")

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match I18n.t("admin.illustrations.broken_title"), response.body
    assert_match "/lesson-images/net-takogo.svg", response.body
    # A broken reference never renders as an <img> — only as a called-out row.
    assert_select "img.illustration-card__thumb", 0
  end

  test "empty profession shows both quiet empty states" do
    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match I18n.t("admin.illustrations.pending_empty"), response.body
    assert_match I18n.t("admin.illustrations.gallery_empty"), response.body
  end

  test "unknown profession slug is not found" do
    get admin_illustrations_path(path: "net-takoy")
    assert_response :not_found
  end
end
