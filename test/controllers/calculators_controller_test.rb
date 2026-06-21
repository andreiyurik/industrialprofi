require "test_helper"

class CalculatorsControllerTest < ActionDispatch::IntegrationTest
  test "index lists every calculator grouped by category" do
    get calculators_path
    assert_response :success
    assert_select ".calc-row", Calculator.all.size
    assert_select ".calc-group", Calculator.grouped.size
    assert_match I18n.t("calculators.categories.electrician"), response.body
  end

  test "each calculator renders its form, source and disclaimer" do
    Calculator.all.each do |calculator|
      get calculator_path(calculator)
      assert_response :success, "expected #{calculator.slug} to render"
      assert_select "[data-controller='calculator'][data-calculator-formula-value=?]", calculator.formula
      assert_match calculator.title, response.body
      assert_match I18n.t("calculators.disclaimer"), response.body
    end
  end

  test "unknown calculator slug is a 404" do
    get calculator_path("does-not-exist")
    assert_response :not_found
  end

  test "a calculator links its related lesson only when that lesson exists" do
    get calculator_path("ohms-law")
    if Lesson.exists?(slug: "01-zakon-oma-i-kirkhgofa")
      assert_select ".calc-lesson-link"
    else
      assert_select ".calc-lesson-link", false
    end
  end

  test "calculators are public" do
    get calculators_path
    assert_response :success
    get calculator_path("pressure")
    assert_response :success
  end
end
