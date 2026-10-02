require "test_helper"

class IllustrationCensusTest < ActiveSupport::TestCase
  test "a lesson with a placeholder or a real image counts as covered, a bare one does not" do
    path = paths(:electrician)
    lessons = path.lessons.ordered.to_a
    lessons.first.update!(body: "![Схема](TODO-shema.png)")
    lessons.second.update!(body: "![Готовая](/icon.png)")

    census = IllustrationCensus.new(path)
    assert_equal lessons.size, census.lessons_total
    assert_equal 2, census.covered_lessons_count
    assert_equal lessons.drop(2), census.uncovered_lessons
  end

  test "a broken image does not cover its lesson" do
    path = paths(:electrician)
    path.lessons.first.update!(body: "![Пропала](/lesson-images/net-takogo.svg)")

    assert_equal 0, IllustrationCensus.new(path).covered_lessons_count
  end

  test "a profession without lessons is fully covered so it never ranks worst" do
    empty = Path.create!(title: "Пустая", slug: "pustaya", description: "x")
    assert_equal 1.0, IllustrationCensus.new(empty).coverage
  end
end
