require "application_system_test_case"

# The three calculators that draw. Their maths is already covered by the values
# rendered into the result rows; what only a browser can prove is that the
# diagram tracks the form — the reason these got their own controllers.
class CalculatorsTest < ApplicationSystemTestCase
  test "the Ohm wheel separates what you entered from what it worked out" do
    visit calculator_path("ohms-law")

    # Defaults are U = 12 В and R = 4 Ом, so I and P are the derived pair.
    assert_selector "[data-sector='u'][data-state='given']"
    assert_selector "[data-sector='r'][data-state='given']"
    assert_selector "[data-sector='i'][data-state='derived']"
    assert_selector "[data-sector='p'][data-state='derived']"
    assert_equal "3", find("[data-output='i']").text
    assert_equal "36", find("[data-output='p']").text

    # Clearing a given value hands its sector back to the empty state.
    find("[data-field='r']").set("")
    assert_selector "[data-sector='i'][data-state='empty']"
  end

  test "the voltage drop figure turns red when the line stops meeting the norm" do
    visit calculator_path("voltage-drop")

    assert_selector ".drop-figure[data-state='ok']"
    assert_selector "[data-figure='load']", text: "372,4 В"

    find("[data-field='l']").set("300")
    assert_selector ".drop-figure[data-state='warn']"
    assert_selector ".calc-answer[data-status='warn']"
  end

  test "the voltage drop slider fills its number input" do
    visit calculator_path("voltage-drop")

    range = find("[data-range-for='l']", visible: :all)
    range.execute_script("this.value = 250; this.dispatchEvent(new Event('input', { bubbles: true }))")

    assert_equal "250", find("[data-field='l']").value
    assert_selector ".drop-figure[data-state='warn']"
  end

  test "golden hour computes on load and offers to fetch the reader's place" do
    visit calculator_path("golden-hour")

    # Defaults are Moscow and today, so every slot must hold a real time.
    assert_selector ".calc-answer [data-output='golden']", text: /\d{2}:\d{2} — \d{2}:\d{2}/
    assert_selector "[data-output='sunset']", text: /\d{2}:\d{2}/
    assert_selector ".calc-locate .btn", text: I18n.t("calculators.golden-hour.locate")
    assert_equal Date.current.day.to_s, find("[data-field='day']").value
  end

  test "the verdict states the outcome in words and follows the numbers" do
    visit calculator_path("voltage-drop")
    assert_selector ".calc-verdict[data-status='ok']", text: I18n.t("calculators.voltage-drop.verdict_ok")

    find("[data-field='l']").set("300")
    assert_selector ".calc-verdict[data-status='warn']", text: I18n.t("calculators.voltage-drop.verdict_warn")
  end

  test "a soil preset fills the resistivity field and steps back when it is edited" do
    visit calculator_path("grounding")

    find("[data-preset-for='rho']").select(I18n.t("calculators.grounding.soil_sand"))
    assert_equal "500", find("[data-field='rho']").value

    find("[data-field='rho']").set("123")
    assert_equal "", find("[data-preset-for='rho']").value
  end

  test "copying a result works on a calculator that runs its own controller" do
    visit calculator_path("voltage-drop")

    find(".calc-answer .calc-copy").click
    assert_selector ".calc-copy--done"
  end

  test "the loop gauge marks where the signal sits and flags a signal out of range" do
    visit calculator_path("ma-scaling")

    # 12 мА on a 4–20 мА span mapped to 0…100 is dead centre.
    assert_selector ".loop-gauge[data-state='ok']"
    assert_selector "[data-figure='value']", text: "50"
    assert_equal "50", find("[data-output='eu']").text

    find("[data-field='ma']").set("24")
    assert_selector ".loop-gauge[data-state='out']"
  end
end
