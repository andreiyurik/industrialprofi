require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    LessonSearch.rebuild
  end

  test "search page is public" do
    get search_path

    assert_response :success
    assert_select "input[name=q]"
  end

  test "shows matching lessons with a link" do
    get search_path(q: "заземлению")

    assert_response :success
    assert_select "a[href=?]", lesson_path(lessons(:zazemlenie))
    assert_select ".search-result__snippet mark"
  end

  test "shows an honest empty state" do
    get search_path(q: "квантовая хромодинамика")

    assert_response :success
    assert_select ".search__empty"
  end
end
