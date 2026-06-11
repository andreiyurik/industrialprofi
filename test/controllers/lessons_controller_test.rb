require "test_helper"

class LessonsControllerTest < ActionDispatch::IntegrationTest
  test "show returns success for published lesson" do
    get lesson_path(lessons(:pteep))
    assert_response :success
    assert_match lessons(:pteep).title, response.body
  end

  test "show returns 404 for unknown slug" do
    get lesson_path(slug: "nonexistent")
    assert_response :not_found
  end

  test "show displays resources" do
    get lesson_path(lessons(:pteep))
    assert_match resources(:pteep_doc).title, response.body
  end

  test "sidebar shows the current course's contents" do
    get lesson_path(lessons(:gruppy_dopuska))
    assert_match courses(:el_basics).title, response.body  # sidebar header = course
    assert_match lessons(:pteep).title, response.body      # sibling lesson in same course
  end

  test "next link flows across course boundaries within the profession" do
    # gruppy_dopuska is the last lesson of el_basics; next is the first of el_pue.
    get lesson_path(lessons(:gruppy_dopuska))
    assert_match lesson_path(lessons(:zazemlenie)), response.body
  end

  test "show markdown format returns raw markdown" do
    get lesson_path(lessons(:pteep), format: :md)
    assert_response :success
    assert_match %r{text/markdown}, response.content_type
    assert_includes response.body, lessons(:pteep).title
    assert_includes response.body, lessons(:pteep).body
  end

  test "show renders markdown in html body" do
    get lesson_path(lessons(:pteep))
    assert_select "div.prose"
  end

  test "show renders the lesson toc with anchored body headings" do
    get lesson_path(lessons(:pteep))
    assert_select "aside.lesson-toc" do
      assert_select ".lesson-toc__link[href='#study']"
      # anchors are transliterated to ASCII (Turbo can't scroll to Cyrillic fragments)
      assert_select ".lesson-toc__link--sub[href='#poryadok-dopuska-k-rabotam']", text: "Порядок допуска к работам"
    end
    # the in-body heading itself carries the matching anchor
    assert_select "h2#poryadok-dopuska-k-rabotam"
  end
end
