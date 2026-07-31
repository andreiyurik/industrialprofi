# Industrial calculators / converters — the kind of tool a tradesperson googles
# before every job ("расчёт сечения кабеля", "4-20 мА в единицы"). They bring
# people back and rank one page per query, but our edge over the calculator
# farms is the link to the *standard* and the *lesson* behind each number.
#
# These are static tools (like the about/faq pages), NOT user content, so they
# live in code — a tiny registry, no table (YAGNI: add a model only if experts
# start authoring their own). Each entry maps a slug to a category and an
# optional related lesson. All human text (title, intro, the normative note)
# lives in config/locales as calculators.<slug>.*; the form markup lives in
# app/views/calculators/forms/_<slug>.html.erb and the math in the single
# calculator Stimulus controller.
class Calculator
  CATEGORIES = %w[electrician kipia photo].freeze

  attr_reader :slug, :category, :lesson_slug

  def initialize(slug, category:, lesson: nil)
    @slug = slug
    @category = category
    @lesson_slug = lesson
  end

  ALL = [
    new("cable-cross-section", category: "electrician", lesson: "02-vybor-secheniya-kabelya"),
    new("ohms-law",            category: "electrician", lesson: "01-zakon-oma-i-kirkhgofa"),
    new("voltage-drop",        category: "electrician"),
    new("grounding",           category: "electrician", lesson: "03-soprotivlenie-zazemleniya"),
    new("rcd",                 category: "electrician", lesson: "02-uzo-i-difavtomaty"),
    new("short-circuit",       category: "electrician", lesson: "02-vybor-secheniya-kabelya"),
    new("ma-scaling",          category: "kipia",       lesson: "signaly-4-20ma-i-diskretnye"),
    new("pressure",            category: "kipia",       lesson: "datchiki-davleniya-rashoda-urovnya"),
    new("resistance-thermometer", category: "kipia",    lesson: "datchiki-temperatury"),
    new("measurement-error",   category: "kipia",       lesson: "metrologiya-poverka-pogreshnost"),
    new("valve-kv",            category: "kipia",       lesson: "ispolnitelnye-mehanizmy-i-chastotniki"),
    new("subnet",              category: "kipia",       lesson: "osnovy-setey-osi-ip-kabeli"),
    new("modbus-rtu",          category: "kipia",       lesson: "modbus-registry-adresaciya"),
    new("twisted-pair-line",   category: "kipia",       lesson: "osnovy-setey-osi-ip-kabeli"),
    # Фото/видео: здесь норматива в духе ПУЭ нет, опора — физика и статья
    # (как у ohms-law, где в `norm` стоит сама формула, а не стандарт).
    new("hyperfocal",          category: "photo",       lesson: "03-fv-grip-i-giperfokal"),
    new("nd-filter",           category: "photo",       lesson: "02-fv-pravilo-180-i-nd"),
    new("crop-factor",         category: "photo",       lesson: "02-fv-fokusnoe-eto-tochka-zreniya"),
    new("exposure-ev",         category: "photo",       lesson: "03-fv-skolko-sveta-v-stsene"),
    new("diffraction",         category: "photo",       lesson: "03-fv-grip-i-giperfokal"),
    new("golden-hour",         category: "photo",       lesson: "03-fv-efemeridy-i-planirovanie"),
    new("timelapse",           category: "photo",       lesson: "03-fv-banki-nastroek")
  ].freeze

  def self.all = ALL
  def self.find(slug) = ALL.find { it.slug == slug }

  # The reverse of #lesson, derived from the same registry so the two can't
  # drift: a lesson shows the calculators that name it, and a new calculator
  # appears on its lesson the day it is registered — no content edit anywhere.
  # Several may share one lesson (сечение кабеля and ток КЗ both sit on
  # "02-vybor-secheniya-kabelya").
  def self.for_lesson(lesson_slug) = ALL.select { it.lesson_slug == lesson_slug }

  # Title/tagline match for site search and the palette. Twenty-odd entries in
  # memory, so a plain scan beats indexing them — they are code, not content.
  #
  # Matching is по основам, not by substring: Russian inflects, and people type
  # the nominative — «сечение кабеля» has to find «Расчёт сечения кабеля». A
  # real stemmer would be overkill for two dozen headlines, so we compare words
  # trimmed of their ending and require every query word to land somewhere.
  ENDING = 2
  MIN_STEM = 3

  def self.search(query)
    words = tokenize(query).reject { it.length < 2 }
    return [] if words.empty?

    ALL.select do |calculator|
      haystack = tokenize("#{calculator.title} #{calculator.tagline}")
      words.all? { |word| haystack.any? { same_stem?(word, it) } }
    end
  end

  def self.tokenize(text) = text.to_s.downcase.scan(/[[:alnum:]]+/)

  def self.same_stem?(one, other)
    length = [ [ one.length, other.length ].min - ENDING, MIN_STEM ].max
    one[0, length] == other[0, length]
  end
  private_class_method :tokenize, :same_stem?

  # Catalog order = the CATEGORIES order, each group keeping registry order.
  def self.grouped = ALL.group_by(&:category).sort_by { CATEGORIES.index(it.first) }

  # Calculators with their own Stimulus controller — because they draw a diagram
  # or need behaviour the shared formula dispatch can't express. The rest run on
  # the shared `calculator` controller; move a slug here the same day its
  # controller lands in app/javascript/controllers/calculators/.
  CUSTOM = %w[
    cable-cross-section ohms-law voltage-drop grounding ma-scaling resistance-thermometer
    measurement-error subnet twisted-pair-line hyperfocal golden-hour
  ].freeze

  # Нормативные данные, которые страница и показывает читателю, и отдаёт своему
  # расчёту — один источник вместо копии в JS. Здесь же проходит шов на будущие
  # рынки: у немецкого электрика это будет таблица DIN VDE 0298-4, а формула та
  # же. ПУЭ-7, гл. 1.3: таблицы 1.3.4/1.3.6 (медь) и 1.3.7/1.3.8 (алюминий) —
  # длительно допустимые токи, А, по сечению жилы, мм².
  CABLE_NORMS = {
    sections: {
      cu: {
        air: [ [ 1.5, 23 ], [ 2.5, 30 ], [ 4, 41 ], [ 6, 50 ], [ 10, 80 ], [ 16, 100 ], [ 25, 140 ], [ 35, 170 ], [ 50, 215 ], [ 70, 270 ], [ 95, 330 ], [ 120, 385 ] ],
        pipe: [ [ 1.5, 19 ], [ 2.5, 27 ], [ 4, 38 ], [ 6, 46 ], [ 10, 70 ], [ 16, 85 ], [ 25, 115 ], [ 35, 135 ], [ 50, 185 ], [ 70, 225 ], [ 95, 275 ], [ 120, 315 ] ]
      },
      al: {
        air: [ [ 2.5, 24 ], [ 4, 32 ], [ 6, 39 ], [ 10, 60 ], [ 16, 75 ], [ 25, 105 ], [ 35, 130 ], [ 50, 165 ], [ 70, 210 ], [ 95, 255 ], [ 120, 295 ] ],
        pipe: [ [ 2.5, 20 ], [ 4, 28 ], [ 6, 36 ], [ 10, 50 ], [ 16, 60 ], [ 25, 85 ], [ 35, 100 ], [ 50, 140 ], [ 70, 175 ], [ 95, 215 ], [ 120, 245 ] ]
      }
    },
    # Ряд номиналов автоматов по ГОСТ Р 50345 / IEC 60898.
    breakers: [ 6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125 ]
  }.freeze

  # Витая пара: сопротивление жилы по калибру AWG (Ом/м, медь 20 °C) и параметры
  # PoE по IEEE 802.3 — сколько пар несут питание, ток, напряжение источника и
  # минимум на устройстве. Длина канала — ISO/IEC 11801 и ГОСТ Р 53246.
  TWISTED_PAIR_NORMS = {
    awg: [
      { awg: 26, area: 0.129, ohms_per_metre: 0.1345 },
      { awg: 24, area: 0.205, ohms_per_metre: 0.0842 },
      { awg: 23, area: 0.258, ohms_per_metre: 0.0668 },
      { awg: 22, area: 0.326, ohms_per_metre: 0.053 }
    ],
    poe: [
      { std: "af", pairs: 2, current: 0.35, source: 48, minimum: 37 },
      { std: "at", pairs: 2, current: 0.6, source: 50, minimum: 42.5 },
      { std: "bt3", pairs: 4, current: 0.6, source: 50, minimum: 42.5 },
      { std: "bt4", pairs: 4, current: 0.96, source: 52, minimum: 41.1 }
    ],
    channel_metres: 100
  }.freeze

  # ГОСТ 6651-2009: НСХ термопреобразователей сопротивления — R₀ и материал
  # чувствительного элемента, а по материалу — температурный коэффициент α,
  # коэффициенты уравнения Каллендара–Ван Дюзена и рабочий диапазон. По ним
  # считаются оба хода и рисуется кривая на схеме.
  RTD_NORMS = {
    sensors: [
      { type: "pt100", label: "Pt100", r0: 100, material: "pt" },
      { type: "pt500", label: "Pt500", r0: 500, material: "pt" },
      { type: "pt1000", label: "Pt1000", r0: 1000, material: "pt" },
      { type: "100p", label: "100П", r0: 100, material: "p" },
      { type: "50p", label: "50П", r0: 50, material: "p" },
      { type: "100m", label: "100М", r0: 100, material: "m" },
      { type: "50m", label: "50М", r0: 50, material: "m" }
    ],
    materials: {
      pt: { alpha: 0.00385, a: 3.9083e-3, b: -5.775e-7, c: -4.183e-12, range: [ -200, 850 ] },
      p: { alpha: 0.00391, a: 3.9692e-3, b: -5.829e-7, c: -4.3303e-12, range: [ -200, 850 ] },
      m: { alpha: 0.00428, a: 4.28e-3, b: -6.2032e-7, c: 8.5154e-10, range: [ -180, 200 ] }
    }
  }.freeze

  # Единицы давления: значение одной единицы в паскалях. Через них идёт и
  # перевод, и таблица множителей под калькулятором, и порядок строк на
  # странице — он не алфавитный, а по частоте на наших щитах.
  PRESSURE_NORMS = {
    units: [
      { unit: "bar", pascals: 1e5 },
      { unit: "kgf", pascals: 98066.5 },
      { unit: "mpa", pascals: 1e6 },
      { unit: "kpa", pascals: 1e3 },
      { unit: "mmh2o", pascals: 9.80665 },
      { unit: "mmhg", pascals: 133.322 },
      { unit: "atm", pascals: 101325 },
      { unit: "psi", pascals: 6894.757 },
      { unit: "pa", pascals: 1 }
    ]
  }.freeze

  NORMS = {
    "cable-cross-section" => CABLE_NORMS,
    "twisted-pair-line" => TWISTED_PAIR_NORMS,
    "resistance-thermometer" => RTD_NORMS,
    "pressure" => PRESSURE_NORMS
  }.freeze

  def to_param = slug

  def norms = NORMS[slug]

  # camelCase the slug → the method name on the shared calculator Stimulus
  # controller (short-circuit → shortCircuit).
  def formula = slug.gsub(/-([a-z])/) { Regexp.last_match(1).upcase }

  def custom? = CUSTOM.include?(slug)

  def controller = custom? ? "calculators--#{slug}" : "calculator"

  # Everything the calculator panel needs to boot its controller. Kept here so
  # the view stays a single `data:` hash across both wiring styles. A Stimulus
  # value is addressed by the controller's IDENTIFIER, not by the class that
  # declares it — so a calculator with its own controller reads its norms from
  # data-calculators--<slug>-norms-value, not from the shared prefix.
  def stimulus_data
    actions = %w[input->%s#compute change->%s#compute click->%s#copy].map { format(it, controller) }
    data = { controller: controller, action: actions.join(" ") }
    data[:calculator_formula_value] = formula unless custom?
    data[:"#{controller}_norms_value"] = norms.to_json if norms
    data
  end

  def title = I18n.t("calculators.#{slug}.title")
  def tagline = I18n.t("calculators.#{slug}.tagline")

  # The related lesson is rendered only when it actually exists, so a renamed or
  # not-yet-seeded slug simply hides the link instead of 500-ing.
  def lesson
    return nil if lesson_slug.blank?
    return @lesson if defined?(@lesson)
    @lesson = Lesson.find_by(slug: lesson_slug)
  end
end
