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
  CATEGORIES = %w[electrician kipia network].freeze

  attr_reader :slug, :category, :lesson_slug

  def initialize(slug, category:, lesson: nil)
    @slug = slug
    @category = category
    @lesson_slug = lesson
  end

  ALL = [
    new("cable-cross-section", category: "electrician", lesson: "02-vybor-secheniya-kabelya"),
    new("power-current",       category: "electrician"),
    new("ohms-law",            category: "electrician", lesson: "01-zakon-oma-i-kirkhgofa"),
    new("voltage-drop",        category: "electrician"),
    new("grounding",           category: "electrician", lesson: "03-soprotivlenie-zazemleniya"),
    new("short-circuit",       category: "electrician", lesson: "02-vybor-secheniya-kabelya"),
    new("rcd",                 category: "electrician", lesson: "02-uzo-i-difavtomaty"),
    new("ma-scaling",          category: "kipia",       lesson: "signaly-4-20ma-i-diskretnye"),
    new("pressure",            category: "kipia",       lesson: "datchiki-davleniya-rashoda-urovnya"),
    new("resistance-thermometer", category: "kipia",    lesson: "datchiki-temperatury"),
    new("measurement-error",   category: "kipia",       lesson: "metrologiya-poverka-pogreshnost"),
    new("valve-kv",            category: "kipia",       lesson: "ispolnitelnye-mehanizmy-i-chastotniki"),
    new("twisted-pair-line",   category: "network",     lesson: "osnovy-setey-osi-ip-kabeli"),
    new("subnet",              category: "network",     lesson: "osnovy-setey-osi-ip-kabeli"),
    new("modbus-rtu",          category: "network",     lesson: "modbus-registry-adresaciya")
  ].freeze

  def self.all = ALL
  def self.find(slug) = ALL.find { it.slug == slug }

  # Catalog order = the CATEGORIES order, each group keeping registry order.
  def self.grouped = ALL.group_by(&:category).sort_by { CATEGORIES.index(it.first) }

  def to_param = slug

  # camelCase the slug → the method name on the calculator Stimulus controller
  # (cable-cross-section → cableCrossSection).
  def formula = slug.gsub(/-([a-z])/) { Regexp.last_match(1).upcase }

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
