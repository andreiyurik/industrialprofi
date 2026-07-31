require "test_helper"

class CalculatorTest < ActiveSupport::TestCase
  test "for_lesson is the exact reverse of the lesson each calculator names" do
    Calculator.all.each do |calculator|
      next if calculator.lesson_slug.blank?

      assert_includes Calculator.for_lesson(calculator.lesson_slug), calculator
    end
  end

  test "for_lesson returns every calculator sharing one lesson" do
    # Сечение кабеля и ток КЗ стоят на одной статье — блок на ней должен
    # показать оба, а не первый попавшийся.
    shared = Calculator.for_lesson("02-vybor-secheniya-kabelya").map(&:slug)

    assert_includes shared, "cable-cross-section"
    assert_includes shared, "short-circuit"
  end

  test "for_lesson is empty for a lesson no calculator names" do
    assert_empty Calculator.for_lesson("нет-такой-статьи")
  end

  test "search matches a title and a tagline, and ignores case" do
    assert_includes Calculator.search("сечение кабеля").map(&:slug), "cable-cross-section"
    assert_includes Calculator.search("ЗАКОН ОМА").map(&:slug), "ohms-law"
    # "медь и алюминий" живёт только в подзаголовке.
    assert_includes Calculator.search("медь и алюминий").map(&:slug), "cable-cross-section"
  end

  test "search stays quiet on a query too short to mean anything" do
    assert_empty Calculator.search("а")
    assert_empty Calculator.search(" ")
    assert_empty Calculator.search(nil)
  end

  test "every registered calculator has the locale keys its page renders" do
    Calculator.all.each do |calculator|
      assert calculator.title.present?, "#{calculator.slug} has no title"
      assert calculator.tagline.present?, "#{calculator.slug} has no tagline"
      assert_includes Calculator::CATEGORIES, calculator.category
    end
  end
end
