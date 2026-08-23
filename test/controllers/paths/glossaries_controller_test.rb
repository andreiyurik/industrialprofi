require "test_helper"

class Paths::GlossariesControllerTest < ActionDispatch::IntegrationTest
  test "shows this profession's abbreviations under the hub header" do
    get path_glossary_path(paths(:electrician))
    assert_response :success
    assert_select ".hub-tabs__link[aria-current=page][href=?]", path_glossary_path(paths(:electrician))
    assert_select ".glossary-group#elektrik .glossary__term", text: "ПУЭ"
    assert_select ".glossary-group#svarshchik", false
    # The per-profession heading the /glossary page draws is redundant here;
    # the live filter and its empty state ship as on /glossary.
    assert_select ".glossary-group__head", false
    assert_select "[data-controller='glossary-filter'] .glossary-toolbar__input"
    assert_select ".glossary-empty[hidden]"
    assert_select ".glossary__entry#elektrik-ПУЭ"
  end

  test "a profession the registry does not cover has no tab and no page" do
    uncovered = Path.create!(title: "Геодезист", slug: "geodezist", description: "x",
                             position: 9, status: "published")

    get path_glossary_path(uncovered)
    assert_response :not_found

    get path_path(uncovered)
    assert_select ".hub-tabs__link[href=?]", path_glossary_path(uncovered), false
    assert_select ".hub-tabs__link", 4
  end

  test "draft professions are not found" do
    get path_glossary_path(paths(:draft_path))
    assert_response :not_found
  end

  test "re-crawls get a render-free 304 for visitors" do
    get path_glossary_path(paths(:electrician))
    assert response.headers["Last-Modified"].present?

    get path_glossary_path(paths(:electrician)), headers: { "HTTP_IF_MODIFIED_SINCE" => response.headers["Last-Modified"] }
    assert_response :not_modified
  end
end
