require "test_helper"

class Paths::LibrariesControllerTest < ActionDispatch::IntegrationTest
  test "shows the profession's documents under the hub header" do
    get path_library_path(paths(:electrician))
    assert_response :success
    assert_select ".hub-tabs__link[aria-current=page][href=?]", path_library_path(paths(:electrician))
    assert_select "#documents .library-group"
    # Abbreviations have their own tab; no calculator names a fixture lesson →
    # one shelf, so no jump links either.
    assert_select "#terms", false
    assert_select "#tools", false
    assert_select ".hub-jumps", false
  end

  test "the tools shelf appears once a lesson a calculator names exists" do
    Lesson.create!(path: paths(:electrician), course: courses(:el_pue), title: "УЗО и дифавтоматы",
                   slug: "02-uzo-i-difavtomaty", position: 9, body: "x")

    get path_library_path(paths(:electrician))
    assert_select "#tools .calc-row", Calculator.for_path(paths(:electrician)).size
    assert_select "#tools .calc-row[href=?]", calculator_path("rcd")
    # Two shelves now → jump links appear.
    assert_select ".hub-jumps__link", 2
  end

  test "an empty shelf is skipped, and an empty reference says so" do
    # The welder has no documents and no calculators yet.
    get path_library_path(paths(:welder))
    assert_response :success
    assert_select "#documents", false
    assert_select "#tools", false
    assert_match I18n.t("paths.library.empty"), response.body
  end

  test "draft and unknown professions are not found" do
    get path_library_path(paths(:draft_path))
    assert_response :not_found

    get path_library_path(path_slug: "nonexistent")
    assert_response :not_found
  end

  test "the page is canonical and revalidates for visitors" do
    get path_library_path(paths(:electrician))
    assert_select "link[rel=canonical][href=?]", path_library_url(paths(:electrician))
    last_modified = response.headers["Last-Modified"]
    assert last_modified.present?

    get path_library_path(paths(:electrician)), headers: { "HTTP_IF_MODIFIED_SINCE" => last_modified }
    assert_response :not_modified
  end
end
