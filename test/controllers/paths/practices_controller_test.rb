require "test_helper"

class Paths::PracticesControllerTest < ActionDispatch::IntegrationTest
  test "shows only this profession's tasks, as a ladder of levels, under the hub header" do
    get path_practice_path(paths(:electrician))
    assert_response :success
    assert_select ".hub-tabs__link[aria-current=page][href=?]", path_practice_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_path(paths(:electrician))
    assert_select ".hub-tabs__link[href=?]", path_library_path(paths(:electrician))

    # The electrician has one task (advanced): one to-do list, headed by the
    # level's numeral, name and definition; the chapter name on the row.
    assert_select ".todo .todo__list", 1
    assert_select ".todo__title .difficulty-mark--advanced", text: "III"
    assert_select ".todo__title", text: /#{I18n.t("lessons.difficulty.advanced")}/
    assert_select ".todo__hint", text: I18n.t("projects.difficulty_hints.advanced")
    assert_select ".todo__item", 1
    assert_select ".todo__check"
    assert_match "Сборка распределительного щитка", response.body
    assert_select ".todo__meta", false, "a row is a checkbox and a name — nothing else"
    assert_no_match(/Первый сварной шов/, response.body)
    # Guests see no controls at all — the levels are the structure.
    assert_select ".hub-section__toggle", false
  end

  test "saved filter shows only bookmarked tasks of this profession" do
    users(:member).lesson_bookmarks.create!(lesson: lessons(:praktika_svarka))
    sign_in_as users(:member)

    get path_practice_path(paths(:electrician), saved: "1")
    assert_select ".todo__item", 0
    assert_match I18n.t("projects.empty_saved"), response.body

    get path_practice_path(paths(:welder), saved: "1")
    assert_select ".todo__item", 1
    assert_select ".bookmark-btn--on"
    assert_select ".hub-section__toggle[aria-current]"
  end

  test "a done task is ticked and struck through, and its list counts it" do
    users(:member).lesson_completions.create!(lesson: lessons(:praktika_shchitok))
    sign_in_as users(:member)

    get path_practice_path(paths(:electrician))
    assert_select ".todo__item--done .todo__check .icon--check", 1
    assert_select ".todo__count--complete", text: "1 из 1"
  end

  test "draft and unknown professions are not found" do
    get path_practice_path(paths(:draft_path))
    assert_response :not_found

    get path_practice_path(path_slug: "nonexistent")
    assert_response :not_found
  end

  test "the wrong locale prefix 301s to the profession's own" do
    get "/en/paths/#{paths(:electrician).slug}/practice"
    assert_redirected_to "/ru/paths/#{paths(:electrician).slug}/practice"
    assert_response :moved_permanently
  end

  test "anonymous visitors revalidate with a 304" do
    get path_practice_path(paths(:electrician))
    last_modified = response.headers["Last-Modified"]
    assert last_modified.present?

    get path_practice_path(paths(:electrician)), headers: { "HTTP_IF_MODIFIED_SINCE" => last_modified }
    assert_response :not_modified
  end
end
