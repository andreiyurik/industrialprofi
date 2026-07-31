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

  test "palette frame renders compact results" do
    get search_path(q: "заземлению"), headers: { "Turbo-Frame" => "palette_results" }

    assert_response :success
    assert_select "turbo-frame#palette_results" do
      assert_select "a.palette-result[href=?]", lesson_path(lessons(:zazemlenie))
      assert_select "a.palette__all[href=?]", search_path(q: "заземлению")
    end
  end

  test "survives raw unencoded bytes in the query string" do
    # Sloppy bots send Cyrillic bytes without percent-encoding; Rack keeps the
    # query string BINARY, which used to crash og:url rendering with a 500.
    get search_path, env: { "QUERY_STRING" => "q=\xD0\xBF\xD1\x80\xD0\xBE".b }

    assert_response :success
  end

  test "palette frame with a blank query shows the quick destinations" do
    get search_path, headers: { "Turbo-Frame" => "palette_results" }

    assert_response :success
    assert_select "turbo-frame#palette_results .palette__quick a", 3
  end
test "a calculator is findable by the query it answers" do
  get search_path(q: "сечение кабеля")

  assert_response :success
  assert_select ".search__group"
  assert_select "a[href=?]", calculator_path(Calculator.find("cable-cross-section"))
end

test "the palette offers calculators above the articles" do
  get search_path(q: "закон ома"), headers: { "Turbo-Frame" => "palette_results" }

  assert_response :success
  assert_select "a.palette-result[href=?]", calculator_path(Calculator.find("ohms-law"))
end

test "a query that only a calculator answers is not an empty state" do
  get search_path(q: "перевод единиц давления")

  assert_response :success
  assert_select ".search__empty", false
  assert_select "a[href=?]", calculator_path(Calculator.find("pressure"))
end
end
