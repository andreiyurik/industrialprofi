# A professional abbreviation, decoded («ПУЭ — Правила устройства
# электроустановок»), owned by the lesson that explains it — exactly as a
# Resource is a lesson's link. A profession's dictionary (its hub «Словарь» tab
# and the site-wide /glossary) is derived from these rows, so an editor adds a
# term where they explain it and it appears everywhere on its own. Scope is
# deliberately narrow — abbreviations with расшифровка and one line of context;
# explaining concepts is the lesson's job.
class GlossaryTerm < ApplicationRecord
  belongs_to :lesson

  validates :abbr, presence: true, length: { maximum: 40 }, uniqueness: { scope: :lesson_id }
  validates :full, presence: true, length: { maximum: 200 }
  validates :note, length: { maximum: 200 }
  validates :analog, length: { maximum: 40 }
  # Provenance only — edit-safety rides on the parent lesson's freeze, as with
  # resources (the importer syncs terms only while the lesson is pristine).
  validates :origin, inclusion: { in: Importable::ORIGINS }
  # A dictionary defines a mark once: other articles link to the one that
  # explains it. Scoped to the profession, not the lesson — two authors must
  # not each define «УЗО» in their own article of the same map.
  validate :single_definition_per_profession

  # Dictionary order: русскоязычные marks first, then international, each run
  # alphabetical — the order the dictionary page reads in, so a lesson's own
  # list and the editor's rows agree with it. Abbreviations are upper-case by
  # nature, so byte order within a script is the alphabet.
  scope :alphabetical, -> { order(Arel.sql("CASE WHEN abbr GLOB '*[А-яЁё]*' THEN 0 ELSE 1 END, abbr")) }
  # Terms visible on the public site: their lesson's course AND profession are
  # both published (the Resource.published rule).
  scope :published, -> {
    joins(lesson: [ :course, :path ])
      .where(courses: { status: "published" }, paths: { status: "published" })
  }

  # One profession's public dictionary, lessons preloaded for the entry links.
  def self.for_path(path)
    published.where(lessons: { path_id: path.id }).includes(:lesson).alphabetical
  end

  # => [[Path, [term, …]], …] in catalog order, for the site-wide /glossary —
  # one query, grouped in Ruby.
  def self.by_path(locale: I18n.locale)
    published.where(paths: { locale: locale }).includes(lesson: :path).alphabetical
             .group_by { |term| term.lesson.path }
             .sort_by { |path, _terms| path.position }
  end

  # Anchor within the profession's page («elektrik-ПУЭ») — Cyrillic ids are
  # valid HTML. Slashes and spaces fold to dashes («МИГ/МАГ» → «МИГ-МАГ»): a
  # "/" id works for fragment navigation but breaks CSS selectors and URLs.
  def anchor = abbr.gsub(%r{[\s,/]+}, "-")

  # Derived, not authored: any Cyrillic in the abbreviation marks it as
  # русскоязычное (ГОСТ/приказы, incl. mixed marks like ВВГнг(А)-LS), otherwise
  # it's international (IEC/EN). Nobody should maintain this by hand.
  def script = abbr.match?(/\p{Cyrillic}/) ? "ru" : "int"

  private
    def single_definition_per_profession
      return if abbr.blank? || lesson.nil?

      other = GlossaryTerm.joins(:lesson).where(lessons: { path_id: lesson.path_id }, abbr: abbr)
                          .where.not(lesson_id: lesson_id).includes(:lesson).first
      errors.add(:abbr, :defined_elsewhere, lesson: other.lesson.title) if other
    end
end
