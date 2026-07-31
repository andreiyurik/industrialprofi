require "application_system_test_case"

# Чистая математика калькуляторов — таблицей случаев, а не одним проходом через
# форму. Модули грузятся тем же импортмапом, что и страница, поэтому проверяется
# ровно тот код, который уедет в прод, и для этого не нужны ни Node, ни сборка.
# Формулы возвращают числа, так что здесь нет ни DOM, ни форматирования: «на
# входе столько — на выходе столько», включая границы, где ответа нет вовсе.
class CalculatorMathTest < ApplicationSystemTestCase
  DELTA = 0.01

  setup do
    # Годится любая страница калькулятора: от неё нужен только импортмап.
    visit calculator_path("ohms-law")
  end

  test "сечение подбирается по таблице ПУЭ, а автомат — между нагрузкой и жилой" do
    norms = Calculator::CABLE_NORMS.as_json

    # 10 кВт, три фазы 380 В, cos φ 0,95 — те же 16 А, что в примере на странице.
    power = electrical("cableCrossSection", { p: 10, phase: "3", material: "cu", laying: "air", cos: 0.95 }, norms)
    assert_in_delta 15.99, power["current"], DELTA
    assert_equal 1.5, power["section"]
    assert_equal 23, power["allowed"]
    assert_equal 20, power["breaker"]
    assert_equal 0, power["index"]

    # Ток задан напрямую — мощность не нужна, ответ едет по той же таблице.
    direct = electrical("cableCrossSection", { i: 96, phase: "3", material: "cu", laying: "air" }, norms)
    assert_equal 16, direct["section"]
    assert_equal 100, direct["allowed"]

    # В трубе та же нагрузка требует толще жилы, чем открыто в воздухе.
    pipe = electrical("cableCrossSection", { i: 96, phase: "3", material: "cu", laying: "pipe" }, norms)
    assert_equal 25, pipe["section"]

    # Выше последней строки таблицы сечения нет — и выдумывать его нельзя.
    over = electrical("cableCrossSection", { i: 500, phase: "3", material: "cu", laying: "air" }, norms)
    assert_nil over["section"]
    assert_nil over["index"]
    assert_nil over["breaker"]
  end

  test "падение напряжения растёт с длиной и упирается в норму 5 %" do
    line = { l: 50, i: 20, s: 4, u: 380, material: "cu", phase: "3" }

    short = electrical("voltageDrop", line)
    assert_in_delta 7.58, short["drop"], DELTA
    assert_in_delta 1.99, short["percent"], DELTA
    assert_in_delta 372.42, short["remaining"], DELTA
    assert_equal true, short["withinLimit"]

    long = electrical("voltageDrop", line.merge(l: 300))
    assert_in_delta 11.96, long["percent"], DELTA
    assert_equal false, long["withinLimit"]

    # Алюминий той же длины и сечения теряет больше меди.
    assert_operator electrical("voltageDrop", line.merge(material: "al"))["drop"], :>, short["drop"]

    # Без сечения считать нечего.
    assert_nil electrical("voltageDrop", line.merge(s: nil))["drop"]
  end

  test "контур заземления считает группу и число электродов до нормы" do
    loop_soil = { rho: 100, psi: 1.5, l: 3, d: 16, h: 0.7, n: 4, eta: 0.7, target: 4 }

    four = electrical("grounding", loop_soil)
    assert_in_delta 49.99, four["single"], DELTA
    assert_in_delta 17.85, four["group"], DELTA
    assert_equal 18, four["required"]
    assert_equal false, four["withinTarget"]

    # Ровно столько электродов, сколько потребовал расчёт, — норма выполняется.
    enough = electrical("grounding", loop_soil.merge(n: four["required"]))
    assert_operator enough["group"], :<=, 4
    assert_equal true, enough["withinTarget"]

    # Электрод длиннее — сопротивление меньше и штук нужно меньше.
    assert_operator electrical("grounding", loop_soil.merge(l: 6))["single"], :<, four["single"]
  end

  test "подсеть режется по префиксу, а /31 и /32 живут по своим правилам" do
    twenty_four = kipia("subnet", { ip: "192.168.1.10", prefix: 24 })
    assert_equal 254, twenty_four["hosts"]
    assert_equal "192.168.1.0", dotted(twenty_four["network"])
    assert_equal "255.255.255.0", dotted(twenty_four["mask"])
    assert_equal "192.168.1.255", dotted(twenty_four["broadcast"])
    assert_equal "192.168.1.1", dotted(twenty_four["hostmin"])
    assert_equal "192.168.1.254", dotted(twenty_four["hostmax"])

    # RFC 3021: в /31 оба адреса раздаются хостам, в /32 остаётся один.
    assert_equal 2, kipia("subnet", { ip: "10.0.0.4", prefix: 31 })["hosts"]
    assert_equal 1, kipia("subnet", { ip: "10.0.0.4", prefix: 32 })["hosts"]

    # Мусор и выход за 32 бита — не ответ, а его отсутствие.
    assert_nil kipia("subnet", { ip: "10.0.", prefix: 24 })["prefix"]
    assert_nil kipia("subnet", { ip: "10.0.0.300", prefix: 24 })["prefix"]
    assert_nil kipia("subnet", { ip: "10.0.0.1", prefix: 33 })["prefix"]
  end

  test "погрешность сравнивается с классом точности по приведённой" do
    check = { measured: 50.4, actual: 50, span: 100, cls: 0.5 }

    good = kipia("measurementError", check)
    assert_in_delta 0.4, good["abs"], DELTA
    assert_in_delta 0.8, good["rel"], DELTA
    assert_in_delta 0.4, good["reduced"], DELTA
    assert_equal true, good["withinClass"]

    assert_equal false, kipia("measurementError", check.merge(measured: 52))["withinClass"]

    # Занижает — знак сохраняется, годность считается по модулю.
    low = kipia("measurementError", check.merge(measured: 49.8))
    assert_operator low["reduced"], :<, 0
    assert_equal true, low["withinClass"]

    # Без класса точности вердикта нет, а погрешности всё равно считаются.
    assert_nil kipia("measurementError", check.merge(cls: nil))["withinClass"]
    assert_nil kipia("measurementError", { measured: nil, actual: 50, span: 100, cls: 0.5 })["abs"]
  end

  test "линия PoE теряет напряжение по калибру жилы и числу пар" do
    norms = Calculator::TWISTED_PAIR_NORMS.as_json

    fine = kipia("twistedPairLine", { std: "at", awg: "24", l: 50 }, norms)
    assert_in_delta 4.21, fine["loop"], DELTA
    assert_in_delta 2.53, fine["drop"], DELTA
    assert_in_delta 47.47, fine["atDevice"], DELTA
    assert_equal true, fine["withinLimit"]

    # Тонкий патч-корд на сотне метров до минимума PD уже не дотягивает.
    thin = kipia("twistedPairLine", { std: "at", awg: "26", l: 100 }, norms)
    assert_equal false, thin["withinLimit"]
    assert_operator thin["maxLength"], :<, 100

    # 802.3bt питает четырьмя парами: жилы параллелятся, шлейф вдвое меньше.
    four_pairs = kipia("twistedPairLine", { std: "bt3", awg: "24", l: 50 }, norms)
    assert_in_delta fine["loop"] / 2, four_pairs["loop"], DELTA

    # Предельная длина в любом случае упирается в длину канала.
    assert_equal 100, kipia("twistedPairLine", { std: "at", awg: "22", l: 10 }, norms)["maxLength"]
  end

  test "термосопротивление ходит в обе стороны и молчит вне диапазона" do
    norms = Calculator::RTD_NORMS.as_json

    assert_in_delta 138.505, kipia("rtdResistance", norms, "pt100", 100), DELTA
    assert_in_delta 100.0, kipia("rtdTemperature", norms, "pt100", 138.505), DELTA
    assert_in_delta 100.0, kipia("rtdResistance", norms, "pt100", 0), DELTA
    assert_in_delta 1385.05, kipia("rtdResistance", norms, "pt1000", 100), DELTA

    # Ниже нуля работает своя ветвь уравнения, у меди — со своим членом.
    assert_in_delta 60.256, kipia("rtdResistance", norms, "pt100", -100), DELTA
    assert_in_delta 34.179, kipia("rtdResistance", norms, "100m", -150), DELTA

    # У меди диапазон уже платины: 900 °C и 300 Ом за его краями.
    assert_nil kipia("rtdResistance", norms, "100m", 900)
    assert_nil kipia("rtdTemperature", norms, "100m", 300)
    assert_equal [ -180, 200 ], kipia("rtdRange", norms, "100m")
    assert_equal [ -200, 850 ], kipia("rtdRange", norms, "pt100")
  end

  test "ГРИП уходит в бесконечность ровно на гиперфокале" do
    wide = { f: 25, n: 8, c: 0.03, s: 3000 }

    far_focus = photo("hyperfocal", wide)
    assert_in_delta 2629.2, far_focus["h"], 0.5
    assert_in_delta 1400.2, far_focus["near"], 0.5
    assert_equal "Infinity", far_focus["far"]

    near_focus = photo("hyperfocal", wide.merge(s: 1500))
    assert_in_delta 957.6, near_focus["near"], 0.5
    assert_in_delta 3459.4, near_focus["far"], 0.5

    # Фокусировка ровно на гиперфокале даёт ближнюю границу в его половине.
    at_hyperfocal = photo("hyperfocal", wide.merge(s: far_focus["h"]))
    assert_in_delta far_focus["h"] / 2, at_hyperfocal["near"], 1
    assert_equal "Infinity", at_hyperfocal["far"]

    # Закрытая диафрагма приближает гиперфокал, длинное фокусное — отодвигает.
    assert_operator photo("hyperfocal", wide.merge(n: 16))["h"], :<, far_focus["h"]
    assert_operator photo("hyperfocal", wide.merge(f: 50))["h"], :>, far_focus["h"]

    assert_nil photo("hyperfocal", wide.merge(f: nil))["h"]
  end

  private
    def electrical(...) = math("calculators/math/electrical", ...)
    def kipia(...) = math("calculators/math/kipia", ...)
    def photo(...) = math("calculators/math/photo", ...)

    def dotted(address) = math("calculators/math/kipia", "toDottedQuad", address)

    # Вызывает функцию модуля в браузере и возвращает её результат в Ruby.
    # Бесконечность JSON не переживает, поэтому нечисловые числа приезжают
    # строкой — «∞» тут такой же значимый ответ, как и любое число.
    def math(module_name, function, *arguments)
      result = page.evaluate_async_script(<<~JS, module_name, function, arguments)
        const [ name, called, args, done ] = arguments
        const plain = (value) => {
          if (typeof value === "number") return Number.isFinite(value) ? value : String(value)
          if (Array.isArray(value)) return value.map(plain)
          if (value && typeof value === "object") {
            return Object.fromEntries(Object.entries(value).map(([ key, inner ]) => [ key, plain(inner) ]))
          }
          return value
        }
        import(name)
          .then((module) => done(plain(module[called](...args))))
          .catch((error) => done({ error: String(error) }))
      JS

      # Иначе упавший импорт или опечатка в имени функции вернули бы «ничего»,
      # и половина проверок на отсутствие ответа прошла бы по ошибке.
      raise "#{module_name}##{function}: #{result["error"]}" if result.is_a?(Hash) && result["error"]

      result
    end
end
