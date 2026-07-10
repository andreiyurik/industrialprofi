require "test_helper"

class LessonSearchTest < ActiveSupport::TestCase
  setup do
    LessonSearch.rebuild
  end

  test "finds a published lesson by a body word" do
    results = LessonSearch.new("заземлению").results

    assert_includes results.map { |r| r.lesson }, lessons(:zazemlenie)
  end

  test "ranks a title hit above a body mention" do
    results = LessonSearch.new("заземление").results

    assert_equal lessons(:zazemlenie), results.first.lesson
  end

  test "prefix-matches Russian word forms" do
    assert_includes LessonSearch.new("заземл").results.map { |r| r.lesson }, lessons(:zazemlenie)
  end

  test "wraps matches in mark inside the snippet" do
    result = LessonSearch.new("заземлению").results.find { |r| r.lesson == lessons(:zazemlenie) }

    assert_includes result.snippet, "<mark>"
  end

  test "hides lessons from unpublished paths and courses" do
    draft = lessons(:draft_lesson)
    draft.update!(title: "Уникальнейшая тема черновика")

    assert_empty LessonSearch.new("уникальнейшая").results
  end

  test "FTS operators in user input are inert" do
    assert_nothing_raised do
      assert_empty LessonSearch.new(%q(" OR 1; DROP TABLE lessons --)).results
      assert_empty LessonSearch.new("NEAR(a b) OR -x").results.select { false }
    end
  end

  test "blank query returns nothing" do
    assert_empty LessonSearch.new("   ").results
  end

  test "index follows the lesson through create, update and destroy" do
    lesson = Lesson.create!(course: courses(:el_basics), title: "Термокарандаш и пирометрия",
                            slug: "termokarandash", position: 99, kind: "lesson",
                            body: "Проверка нагрева контактов")

    assert_includes LessonSearch.new("термокарандаш").results.map { |r| r.lesson }, lesson

    lesson.update!(title: "Пирометрия контактов")
    assert_empty LessonSearch.new("термокарандаш").results

    lesson.destroy!
    assert_empty LessonSearch.new("пирометрия").results
  end
end
