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

  test "shows a lesson's placeholder brief and links into its fill screen" do
    lesson = lessons(:pteep)
    lesson.update!(body: "Текст.\n\n![Схема допуска — кто кого допускает](TODO-elektrik-dopusk.png)\n\nЕщё текст.")

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match "Схема допуска", response.body
    assert_match lesson.title, response.body
    assert_select "a[href=?]", new_admin_lesson_illustration_path(lesson, src: "TODO-elektrik-dopusk.png")
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

  # Fill screen

  test "fill screen shows the brief for the matched placeholder" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема допуска](TODO-elektrik-dopusk.png)")

    get new_admin_lesson_illustration_path(lesson, src: "TODO-elektrik-dopusk.png")
    assert_response :success
    assert_match "Схема допуска", response.body
    assert_select "input[type=hidden][name=?][value=?]", "illustration[src]", "TODO-elektrik-dopusk.png"
    assert_select "input[type=file]"
  end

  test "fill screen without an identifier offers the slot chooser" do
    lessons(:pteep).update!(body: "![Одна](TODO-a.png)\n\n![Другая](TODO-b.png)")

    get new_admin_lesson_illustration_path(lessons(:pteep))
    assert_response :success
    assert_select "a[href=?]", new_admin_lesson_illustration_path(lessons(:pteep), src: "TODO-a.png")
    assert_select "a[href=?]", new_admin_lesson_illustration_path(lessons(:pteep), src: "TODO-b.png")
  end

  test "fill screen is closed to an editor of another profession" do
    sign_out
    sign_in_as users(:editor) # electrician + draft, NOT welder
    get new_admin_lesson_illustration_path(lessons(:svarka_intro))
    assert_redirected_to admin_lessons_path
  end

  test "create fills the placeholder and returns the expert to the article" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема допуска](TODO-elektrik-dopusk.png)")

    assert_difference -> { lesson.lesson_revisions.count } => 1 do
      post admin_lesson_illustrations_path(lesson), params: {
        illustration: { src: "TODO-elektrik-dopusk.png", file: fixture_file_upload("cover.png", "image/png") }
      }
    end

    assert_redirected_to lesson_path(lesson)
    lesson.reload
    assert_includes lesson.body, "](/rails/active_storage/blobs/proxy/"
    assert lesson.illustrations.attached?
  end

  test "a filled image counts as live in the census, not broken" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](TODO-shema.png)")
    post admin_lesson_illustrations_path(lesson), params: {
      illustration: { src: "TODO-shema.png", file: fixture_file_upload("cover.png", "image/png") }
    }

    get admin_illustrations_path(path: paths(:electrician).slug)
    assert_response :success
    assert_match I18n.t("admin.illustrations.pending_empty"), response.body
    assert_no_match I18n.t("admin.illustrations.broken_title"), response.body
    assert_select "img.illustration-card__thumb"
  end

  test "create refuses a non-image upload" do
    lesson = lessons(:pteep)
    lesson.update!(body: "![Схема](TODO-shema.png)")

    post admin_lesson_illustrations_path(lesson), params: {
      illustration: { src: "TODO-shema.png", file: fixture_file_upload("cover.png", "text/plain") }
    }

    assert_redirected_to new_admin_lesson_illustration_path(lesson, src: "TODO-shema.png")
    assert_includes lesson.reload.body, "TODO-shema.png"
  end

  test "create on a vanished placeholder refuses honestly, without corrupting the text" do
    lesson = lessons(:pteep)
    before = lesson.body

    post admin_lesson_illustrations_path(lesson), params: {
      illustration: { src: "TODO-uzhe-net.png", file: fixture_file_upload("cover.png", "image/png") }
    }

    assert_redirected_to new_admin_lesson_illustration_path(lesson)
    assert_equal before, lesson.reload.body
  end
end
