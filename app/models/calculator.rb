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

  # Catalog order = the CATEGORIES order, each group keeping registry order.
  def self.grouped = ALL.group_by(&:category).sort_by { CATEGORIES.index(it.first) }

  # Calculators with their own Stimulus controller — because they draw a diagram
  # or need behaviour the shared formula dispatch can't express. The rest run on
  # the shared `calculator` controller; move a slug here the same day its
  # controller lands in app/javascript/controllers/calculators/.
  CUSTOM = %w[ohms-law voltage-drop ma-scaling golden-hour].freeze

  def to_param = slug

  # camelCase the slug → the method name on the shared calculator Stimulus
  # controller (cable-cross-section → cableCrossSection).
  def formula = slug.gsub(/-([a-z])/) { Regexp.last_match(1).upcase }

  def custom? = CUSTOM.include?(slug)

  def controller = custom? ? "calculators--#{slug}" : "calculator"

  # Everything the calculator panel needs to boot its controller. Kept here so
  # the view stays a single `data:` hash across both wiring styles.
  def stimulus_data
    actions = %w[input->%s#compute change->%s#compute click->%s#copy].map { format(it, controller) }
    data = { controller: controller, action: actions.join(" ") }
    data[:calculator_formula_value] = formula unless custom?
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
