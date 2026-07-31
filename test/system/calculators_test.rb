require "application_system_test_case"

# The calculators that draw. Their maths is already covered by the values
# rendered into the result rows; what only a browser can prove is that the
# diagram tracks the form — the reason these got their own controllers.
class CalculatorsTest < ApplicationSystemTestCase
  test "the section ladder marks the section that carries the calculated current" do
    visit calculator_path("cable-cross-section")

    # 10 кВт на 380 В — это 16 А, и первая же ступень (1,5 мм², 23 А) их держит.
    assert_selector "[data-step='0'][data-state='pick']"
    assert_selector "[data-figure='current']", text: "16 А"
    assert_equal "1,5", find("[data-output='section']").text

    # 60 кВт — 96 А: окно едет за ответом, и он встаёт в середину лестницы.
    find("[data-field='p']").set("60")
    assert_selector "[data-step='2'][data-state='pick']"
    assert_selector "[data-figure='section-2']", text: "16"
  end

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

  test "a timelapse scene preset sets the interval and the clip follows it" do
    visit calculator_path("timelapse")

    # Умолчание 5 с — это и есть пресет заката, поэтому селект стоит на нём.
    assert_equal "5", find("[data-preset-for='interval']").value

    find("[data-preset-for='interval']").select(I18n.t("calculators.timelapse.scene_build"))
    assert_equal "30", find("[data-field='interval']").value
    # Час съёмки с интервалом 30 с — 120 кадров, то есть 4,8 с ролика при 25 к/с.
    assert_equal "120", find("[data-output='frames']").text
    assert_equal "4,8", find("[data-output='clip']").text
  end

  test "copying a result works on a calculator that runs its own controller" do
    visit calculator_path("voltage-drop")

    find(".calc-answer .calc-copy").click
    assert_selector ".calc-copy--done"
  end

  test "the grounding figure shows the rods still missing for the norm" do
    visit calculator_path("grounding")

    # Суглинок, четыре электрода по 3 м: до нормы 4 Ом их нужно восемнадцать.
    assert_equal "18", find("[data-output='nreq']").text
    assert_selector "[data-rod='3'][data-state='set']"
    assert_selector "[data-rod='4'][data-state='needed']"
    assert_selector "[data-more][data-state='on']"

    find("[data-field='n']").set("18")
    assert_selector ".calc-verdict[data-status='ok']"
    assert_selector "[data-rod='11'][data-state='set']"
  end

  test "the PoE line marks the length at which power stops being enough" do
    visit calculator_path("twisted-pair-line")

    # AWG 24 на PoE+ дотягивает дальше 100 м канала — отметке предела там нечего делать.
    assert_selector ".poe-line[data-state='ok']"
    assert_selector "[data-figure='device']", text: "47,5 В"
    assert_equal "off", find("[data-limit]", visible: :all)["data-state"]

    # Тонкий патч-корд упирается в питание раньше конца шкалы.
    find("[data-field='awg']").select(I18n.t("calculators.twisted-pair-line.awg_26"))
    assert_selector "[data-limit][data-state='on']"
    assert_selector "[data-figure='limit']", text: "93 м"

    find("[data-field='l']").set("100")
    assert_selector ".poe-line[data-state='warn']"
  end

  test "the depth of field band runs to infinity once focus reaches the hyperfocal" do
    visit calculator_path("hyperfocal")

    # 25 мм на f/8 — гиперфокал 2,63 м, и фокус по умолчанию стоит дальше него.
    assert_selector ".dof-band[data-state='ok']"
    assert_selector "[data-figure='hyper']", text: "2,63 м"
    assert_equal "∞", find("[data-output='far']").text

    find("[data-field='s']").set("1.5")
    assert_equal "3,46", find("[data-output='far']").text
    assert_selector "[data-figure='focus']", text: "1,5 м"

    # Без фокусного считать нечего — полоса гаснет целиком.
    find("[data-field='f']").set("")
    assert_selector ".dof-band[data-state='empty']"
  end

  test "the RTD curve carries both directions as points on one line" do
    visit calculator_path("resistance-thermometer")

    # Умолчания описывают одну и ту же точку, поэтому на кривой стоят обе метки.
    assert_selector "[data-point='direct'][data-state='on']"
    assert_selector "[data-point='reverse'][data-state='on']"
    assert_selector "[data-figure='t-max']", text: "850 °C"

    # У медного датчика свой диапазон, и 300 Ом в него уже не попадают.
    find("[data-field='type']").select("100М (α 0,00428)")
    assert_selector "[data-figure='t-max']", text: "200 °C"

    find("[data-field='r']").set("300")
    assert_selector "[data-point='reverse'][data-state='off']", visible: :all
    assert_equal "—", find("[data-output='tOut']").text
  end

  test "the tolerance scale puts the error inside or outside the class band" do
    visit calculator_path("measurement-error")

    assert_selector ".tol-scale[data-state='ok']"
    assert_selector "[data-figure='limit']", text: "± 0,5 %"
    assert_selector "[data-figure='value']", text: "0,4 %"

    find("[data-field='measured']").set("52")
    assert_selector ".tol-scale[data-state='warn']"
    assert_selector ".calc-verdict[data-status='warn']"

    # Без класса точности сравнивать не с чем: полоса уходит, метка остаётся.
    find("[data-field='cls']").set("")
    assert_selector ".tol-scale[data-state='plain']"
  end

  test "the bit ruler draws the prefix as the border between network and host bits" do
    visit calculator_path("subnet")

    # /24 — три октета уходят сети, последний целиком остаётся хостам.
    assert_selector "[data-bit='23'][data-state='net']"
    assert_selector "[data-bit='24'][data-state='host']"
    assert_selector "[data-figure='address-0']", text: "192"
    assert_selector "[data-figure='mask-3']", text: "0"

    find("[data-field='prefix']").set("20")
    assert_selector "[data-bit='20'][data-state='host']"
    assert_selector "[data-figure='mask-2']", text: "240"

    # Мусор вместо адреса гасит линейку, а не оставляет старую картинку.
    find("[data-field='ip']").set("10.0.")
    assert_selector ".bit-ruler[data-state='empty']"
    assert_selector "[data-bit='0'][data-state='empty']"
  end

  test "the ND filter says in words whether a filter is needed at all" do
    visit calculator_path("nd-filter")

    # Ясный день на f/2.8 — перебор 6,4 ступени, ближайший стандартный ND64.
    assert_selector ".calc-verdict[data-status='warn']", text: I18n.t("calculators.nd-filter.verdict_warn")
    assert_equal "ND64", find("[data-output='pick']").text

    find("[data-field='n']").set("32")
    assert_selector ".calc-verdict[data-status='ok']", text: I18n.t("calculators.nd-filter.verdict_ok")
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
