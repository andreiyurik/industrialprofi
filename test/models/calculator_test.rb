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

  test "every registered calculator has the locale keys its page renders" do
    Calculator.all.each do |calculator|
      assert calculator.title.present?, "#{calculator.slug} has no title"
      assert calculator.tagline.present?, "#{calculator.slug} has no tagline"
      assert_includes Calculator::CATEGORIES, calculator.category
    end
  end
end
