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
      assert_select "[data-controller=?]", calculator.controller
      # Copy is bound on the panel, so the action has to name whichever
      # controller this calculator actually runs on.
      assert_select "[data-action*=?]", "#{calculator.controller}#copy"
      assert_match calculator.title, response.body
      assert_match I18n.t("calculators.disclaimer"), response.body
    end
  end

  test "a calculator on the shared controller declares the formula to run" do
    Calculator.all.reject(&:custom?).each do |calculator|
      get calculator_path(calculator)
      assert_select "[data-controller='calculator'][data-calculator-formula-value=?]", calculator.formula
    end
  end

  test "a calculator with its own controller boots that one instead" do
    assert Calculator.all.any?(&:custom?)

    Calculator.all.select(&:custom?).each do |calculator|
      get calculator_path(calculator)
      assert_select "[data-controller=?]", "calculators--#{calculator.slug}"
      assert_select "[data-calculator-formula-value]", false
    end
  end

  test "the calculators that draw render their figure" do
    %w[ohms-law voltage-drop ma-scaling].each do |slug|
      get calculator_path(slug)
      assert_select ".calc-figure svg", 1, "expected #{slug} to draw a figure"
    end
  end

  test "a calculator with a verdict says the outcome in words, not only in colour" do
    %w[voltage-drop grounding rcd measurement-error twisted-pair-line short-circuit diffraction].each do |slug|
      get calculator_path(slug)
      assert_select "[data-verdict][data-verdict-ok][data-verdict-warn]", 1, "expected #{slug} to carry a verdict"
    end
  end

  test "every calculator explains how it counts" do
    Calculator.all.each do |calculator|
      get calculator_path(calculator)
      assert_select ".calc-method .calc-method__steps li", minimum: 2,
        message: "expected #{calculator.slug} to walk through its method"
    end
  end

  test "the cable table is rendered from the same norms the calculator runs on" do
    get calculator_path("cable-cross-section")

    assert_select "[data-calculator-norms-value]"
    assert_select ".calc-table tbody tr", Calculator::CABLE_NORMS[:sections].values.flat_map(&:values).flat_map { it.map(&:first) }.uniq.size
    # Первая строка — 1,5 мм²; первая колонка после сечения — медь в воздухе, 23 А.
    assert_select ".calc-table tbody tr:first-child th", "1,5"
    assert_select ".calc-table tbody tr:first-child td:first-of-type", "23"
  end

  test "seeded field values are printed with the locale decimal mark" do
    get calculator_path("grounding")
    assert_select "[data-field='h'][value='0,7']"
    assert_select "[data-field='rho'][value='100']"
  end

  test "unknown calculator slug is a 404" do
    get calculator_path("does-not-exist")
    assert_response :not_found
  end

  test "the merged power-current slug redirects to cable-cross-section" do
    get "/calculators/power-current"
    assert_redirected_to "/calculators/cable-cross-section"
    assert_response :moved_permanently
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
    get calculator_path("ma-scaling")
    assert_response :success
  end
end
